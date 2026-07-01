import Testing
import Foundation
import TestHelpers
@testable import SubstrateSdk

@Suite("WebSocketEngine")
struct WebSocketEngineTests {
    static let url1 = URL(string: "wss://node1.example")!
    static let url2 = URL(string: "wss://node2.example")!

    /// Wires a `WebSocketEngine` to shared mocks. The engine runs on a single serial queue;
    /// events pushed into the mock transport hop through the real `WebSocket` onto that queue,
    /// and the engine re-dispatches completions onto it too, so `drain()` settles all of it
    /// before assertions.
    private final class Harness {
        let engine: WebSocketEngine
        let delegate = MockWebSocketEngineDelegate()
        let factory = MockWebSocketConnectionFactory()
        let queue = DispatchQueue(label: "test.ws.engine")

        /// Transport backing the engine's current connection.
        var transport: MockWebSocketTransport { factory.latest }

        init(
            urls: [URL] = [WebSocketEngineTests.url1],
            autoconnect: Bool = true,
            reconnectionStrategy: ReconnectionStrategyProtocol = StubReconnectionStrategy(delay: 1000),
            customNodeSwitcher: JSONRPCNodeSwitching? = nil
        ) {
            engine = WebSocketEngine(
                urls: urls,
                connectionFactory: factory,
                customNodeSwitcher: customNodeSwitcher,
                reachabilityManager: nil,
                reconnectionStrategy: reconnectionStrategy,
                processingQueue: queue,
                autoconnect: autoconnect,
                pingInterval: 0,
                name: "test"
            )!
            engine.delegate = delegate
        }

        func drain() {
            // Event delivery adds one async hop (WebSocket → engine) and the engine adds
            // another (engine → completion); a few passes over the serial queue settle both.
            for _ in 0 ..< 4 { queue.sync {} }
        }

        func connect() {
            transport.simulateConnected()
            drain()
        }

        func receiveText(_ string: String) {
            transport.simulateText(string)
            drain()
        }

        func serverDisconnect() {
            transport.simulateDisconnected()
            drain()
        }

        func receivePing() {
            transport.simulatePing()
            drain()
        }
    }

    private func resultResponse(id: UInt16, result: String) -> String {
        #"{"jsonrpc":"2.0","result":\#(result),"id":\#(id)}"#
    }

    private func errorResponse(id: UInt16, code: Int, message: String) -> String {
        #"{"jsonrpc":"2.0","error":{"code":\#(code),"message":"\#(message)"},"id":\#(id)}"#
    }

    // MARK: init & connect

    @Test("returns nil when constructed with no urls")
    func returnsNilForEmptyUrls() {
        let engine = WebSocketEngine(urls: [], autoconnect: false)
        #expect(engine == nil)
    }

    @Test("autoconnect opens the socket and enters connecting")
    func autoconnectStartsConnecting() {
        let harness = Harness(autoconnect: true)

        #expect(harness.engine.state == .connecting(url: Self.url1))
        #expect(harness.transport.startCount == 1)
    }

    @Test("does not connect when autoconnect is disabled")
    func noConnectWhenAutoconnectDisabled() {
        let harness = Harness(autoconnect: false)

        #expect(harness.engine.state == .notConnected(url: nil))
        #expect(harness.transport.startCount == 0)
    }

    @Test("reports connected state through the delegate on the connected event")
    func connectedEventUpdatesStateAndDelegate() {
        let harness = Harness(autoconnect: true)

        harness.connect()

        #expect(harness.engine.state == .connected(url: Self.url1))
        #expect(harness.delegate.stateTransitions.last?.to == .connected(url: Self.url1))
    }

    // MARK: request queueing

    @Test("queues requests while connecting and flushes them once connected")
    func queuesRequestsUntilConnected() throws {
        let harness = Harness(autoconnect: true)

        _ = try harness.engine.callMethod(
            "system_health",
            params: [String](),
            options: JSONRPCOptions()
        ) { (_: Result<Int, Error>) in }

        // still connecting → nothing written yet, request is pending
        #expect(harness.transport.sentRequests.isEmpty)
        #expect(harness.engine.pendingRequests.count == 1)

        harness.connect()

        #expect(harness.transport.sentRequests.count == 1)
        #expect(harness.engine.pendingRequests.isEmpty)
    }

    @Test("writes immediately when a call is made while connected")
    func writesImmediatelyWhenConnected() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        _ = try harness.engine.callMethod(
            "system_health",
            params: [String](),
            options: JSONRPCOptions()
        ) { (_: Result<Int, Error>) in }
        harness.drain()

        #expect(harness.transport.sentRequests.count == 1)
    }

    // MARK: responses

    @Test("delivers a successful result to the caller completion")
    func deliversSuccessResult() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        var received: Result<Int, Error>?
        let id = try harness.engine.callMethod(
            "system_health",
            params: [String](),
            options: JSONRPCOptions()
        ) { (result: Result<Int, Error>) in received = result }

        harness.receiveText(resultResponse(id: id, result: "42"))

        #expect(try received?.get() == 42)
        #expect(harness.engine.inProgressRequests.isEmpty)
    }

    @Test("delivers a JSON-RPC error to the caller completion")
    func deliversErrorResult() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        var received: Result<Int, Error>?
        let id = try harness.engine.callMethod(
            "system_health",
            params: [String](),
            options: JSONRPCOptions()
        ) { (result: Result<Int, Error>) in received = result }

        harness.receiveText(errorResponse(id: id, code: 1010, message: "boom"))

        guard case let .failure(error) = received else {
            Issue.record("expected failure, got \(String(describing: received))")
            return
        }
        #expect((error as? JSONRPCError)?.code == 1010)
    }

    // MARK: subscriptions

    @Test("captures the remote id and routes updates to the subscriber")
    func subscriptionCapturesRemoteIdAndDeliversUpdate() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        var updates: [String] = []
        let localId = try harness.engine.subscribe(
            "state_subscribeStorage",
            params: [String](),
            unsubscribeMethod: "state_unsubscribeStorage",
            updateClosure: { (update: JSONRPCSubscriptionUpdate<String>) in
                updates.append(update.params.result)
            },
            failureClosure: { _, _ in }
        )

        // node acknowledges the subscription with its remote id
        harness.receiveText(resultResponse(id: localId, result: "\"REMOTE_1\""))
        #expect(harness.engine.subscriptions[localId]?.remoteId == "REMOTE_1")

        // an update addressed to that remote id reaches the closure
        harness.receiveText(
            #"{"jsonrpc":"2.0","method":"state_storage","params":{"subscription":"REMOTE_1","result":"0xdeadbeef"}}"#
        )
        #expect(updates == ["0xdeadbeef"])
    }

    @Test("cancelling a subscription sends an unsubscribe and drops the handler")
    func cancelSubscriptionUnsubscribesAndRemoves() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        let localId = try harness.engine.subscribe(
            "state_subscribeStorage",
            params: [String](),
            unsubscribeMethod: "state_unsubscribeStorage",
            updateClosure: { (_: JSONRPCSubscriptionUpdate<String>) in },
            failureClosure: { _, _ in }
        )
        harness.receiveText(resultResponse(id: localId, result: "\"REMOTE_1\""))

        let requestsBefore = harness.transport.sentRequests.count
        harness.engine.cancelForIdentifier(localId)
        harness.drain()

        #expect(harness.engine.subscriptions[localId] == nil)
        // an unsubscribe request was written
        #expect(harness.transport.sentRequests.count == requestsBefore + 1)
    }

    // MARK: reconnection

    @Test("re-queues active subscriptions and re-sends them after reconnect")
    func subscriptionSurvivesReconnect() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        let localId = try harness.engine.subscribe(
            "state_subscribeStorage",
            params: [String](),
            unsubscribeMethod: "state_unsubscribeStorage",
            updateClosure: { (_: JSONRPCSubscriptionUpdate<String>) in },
            failureClosure: { _, _ in }
        )
        harness.receiveText(resultResponse(id: localId, result: "\"REMOTE_1\""))
        let requestsAfterSubscribe = harness.transport.sentRequests.count

        // socket drops while connected
        harness.serverDisconnect()

        #expect(harness.engine.state == .waitingReconnection(url: Self.url1))
        // subscription is retained, remote id cleared, and re-queued for replay
        #expect(harness.engine.subscriptions[localId] != nil)
        #expect(harness.engine.subscriptions[localId]?.remoteId == nil)
        #expect(harness.engine.pendingRequests.contains { $0.requestId.itemIds.contains(localId) })

        // reconnect and confirm the subscribe request is re-sent
        harness.engine.connectIfNeeded()
        harness.drain()
        harness.connect()

        #expect(harness.transport.sentRequests.count > requestsAfterSubscribe)
    }

    @Test("does not replay a non-idempotent subscription on reconnect")
    func nonIdempotentSubscriptionCancelledOnReconnect() throws {
        let harness = Harness(autoconnect: true)
        harness.connect()

        var failure: (error: Error, unsubscribed: Bool)?
        let localId = try harness.engine.subscribe(
            "author_submitAndWatchExtrinsic",
            params: [String](),
            unsubscribeMethod: "author_unwatchExtrinsic",
            options: JSONRPCOptions(resendOnReconnect: false),
            updateClosure: { (_: JSONRPCSubscriptionUpdate<String>) in },
            failureClosure: { error, unsubscribed in failure = (error, unsubscribed) }
        )
        harness.receiveText(resultResponse(id: localId, result: "\"REMOTE_1\""))
        #expect(harness.engine.subscriptions[localId]?.remoteId == "REMOTE_1")

        let requestsAfterSubscribe = harness.transport.sentRequests.count

        // socket drops while connected
        harness.serverDisconnect()

        // subscription is cancelled (not re-queued) and the subscriber is notified it ended
        #expect(harness.engine.subscriptions[localId] == nil)
        #expect(!harness.engine.pendingRequests.contains { $0.requestId.itemIds.contains(localId) })
        #expect(failure?.unsubscribed == true)

        // reconnecting must not resend it
        harness.engine.connectIfNeeded()
        harness.drain()
        harness.connect()
        #expect(harness.transport.sentRequests.count == requestsAfterSubscribe)
    }

    @Test("fails pending requests when the reconnection strategy gives up")
    func givingUpFailsPendingRequests() throws {
        let harness = Harness(
            autoconnect: true,
            reconnectionStrategy: StubReconnectionStrategy(delay: nil)
        )
        harness.connect()

        var received: Result<Int, Error>?
        _ = try harness.engine.callMethod(
            "system_health",
            params: [String](),
            options: JSONRPCOptions(resendOnReconnect: false)
        ) { (result: Result<Int, Error>) in received = result }

        harness.serverDisconnect()

        #expect(harness.engine.state == .notConnected(url: Self.url1))
        guard case .failure = received else {
            Issue.record("expected the in-flight request to fail")
            return
        }
    }

    // MARK: node switching

    @Test("switches to the next node when a switch-worthy error code arrives")
    func switchesNodeOnInterceptedErrorCode() throws {
        let switcher = JSONRRPCodeNodeSwitcher(codes: [1013])
        let harness = Harness(urls: [Self.url1, Self.url2], customNodeSwitcher: switcher)
        harness.connect()

        let id = try harness.engine.callMethod(
            "system_health",
            params: [String](),
            options: JSONRPCOptions()
        ) { (_: Result<Int, Error>) in }

        harness.receiveText(errorResponse(id: id, code: 1013, message: "overloaded"))

        #expect(harness.engine.selectedURL == Self.url2)
        #expect(harness.delegate.switchedURLs.contains(Self.url2))
    }

    // MARK: disconnect & ping

    @Test("disconnectIfNeeded gracefully closes and returns to notConnected")
    func disconnectIfNeededClosesSocket() {
        let harness = Harness(autoconnect: true)
        harness.connect()

        harness.engine.disconnectIfNeeded()
        harness.drain()

        #expect(harness.engine.state == .notConnected(url: Self.url1))
        #expect(harness.transport.stopCloseCodes.contains(MockWebSocketTransport.goingAwayCloseCode))
    }

    @Test("answers an inbound websocket ping with a pong while connected")
    func respondsToInboundPingWithPong() {
        let harness = Harness(autoconnect: true)
        harness.connect()

        harness.receivePing()

        #expect(harness.transport.pongCount == 1)
    }
}
