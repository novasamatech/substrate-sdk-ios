import Testing
import Foundation
import TestHelpers
@testable import SubstrateSdk

@Suite("WebSocketEngine reconnect on network path changes")
struct WebSocketEngineReconnectTests {
    static let url = URL(string: "wss://node1.example")!

    @Test("viability loss restarts the connection after the grace period")
    func viabilityLossTriggersReconnect() async {
        let harness = Harness()

        harness.connect()
        harness.transport.simulate(.viabilityChanged(false))

        let didReconnect = await harness.reconnectHappened()
        #expect(didReconnect)

        harness.drain()
        #expect(harness.factory.transports.count == 2)
        #expect(harness.factory.latest.startCount == 1)
    }

    @Test("viability recovery keeps the connection even if the grace timer fires late")
    func viabilityRecoveryKeepsConnection() {
        let harness = Harness(viabilityTimeout: 60)

        harness.connect()
        harness.transport.simulate(.viabilityChanged(false))
        harness.transport.simulate(.viabilityChanged(true))
        harness.drain()

        harness.engine.didTrigger(scheduler: harness.engine.viabilityTimeoutScheduler)
        harness.drain()

        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("better path suggestion reconnects immediately when idle")
    func betterPathTriggersImmediateReconnect() {
        let harness = Harness()

        harness.connect()
        harness.transport.simulate(.reconnectSuggested(true))
        harness.drain()

        #expect(harness.factory.transports.count == 2)
        #expect(harness.factory.latest.startCount == 1)
    }

    @Test("better path waits for a non-resendable in-flight request")
    func betterPathWaitsForInFlight() throws {
        let harness = Harness()

        harness.connect()

        let requestId = try harness.submitNonResendableRequest()
        harness.drain()

        harness.transport.simulate(.reconnectSuggested(true))
        harness.drain()

        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.pendingBetterPathReconnect)

        harness.respond(to: requestId)

        #expect(harness.factory.transports.count == 2)
        #expect(!harness.engine.pendingBetterPathReconnect)
    }

    @Test("withdrawn better path suggestion cancels the deferred reconnect")
    func withdrawnBetterPathCancelsDeferredReconnect() throws {
        let harness = Harness()

        harness.connect()

        let requestId = try harness.submitNonResendableRequest()
        harness.drain()

        harness.transport.simulate(.reconnectSuggested(true))
        harness.transport.simulate(.reconnectSuggested(false))

        harness.respond(to: requestId)

        #expect(harness.factory.transports.count == 1)
        #expect(!harness.engine.pendingBetterPathReconnect)
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("dead path restart drops the deferred better path reconnect")
    func deadPathRestartDropsDeferredReconnect() async throws {
        let harness = Harness()

        harness.connect()

        try harness.submitNonResendableRequest()
        harness.drain()

        harness.transport.simulate(.reconnectSuggested(true))
        harness.transport.simulate(.viabilityChanged(false))

        let didReconnect = await harness.reconnectHappened()
        #expect(didReconnect)

        harness.drain()
        harness.connect()

        let requestId = try harness.submitNonResendableRequest()
        harness.drain()
        harness.respond(to: requestId)

        #expect(harness.factory.transports.count == 2)
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("late pong timeout after pong received does not restart the connection")
    func latePongTimeoutAfterPongIsIgnored() {
        let harness = Harness(pongTimeout: 60)

        harness.connect()

        harness.engine.didTrigger(scheduler: harness.engine.pingScheduler)
        harness.drain()
        #expect(harness.engine.awaitingPong)

        harness.transport.simulate(.pong(nil))
        harness.drain()

        harness.engine.didTrigger(scheduler: harness.engine.pongTimeoutScheduler)
        harness.drain()

        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("missing pong restarts the connection")
    func missingPongTriggersReconnect() async {
        let harness = Harness(pingInterval: 0.3, pongTimeout: 0.1)

        harness.connect()

        let didReconnect = await harness.reconnectHappened()
        #expect(didReconnect)

        harness.drain()
        #expect(harness.factory.transports.first?.pingCount ?? 0 >= 1)
        #expect(harness.factory.transports.count == 2)
    }

    @Test("answered pings keep the connection alive")
    func pongReceptionKeepsConnectionAlive() {
        let harness = Harness(pongTimeout: 60)

        let connection = harness.transport
        connection.onFrame = { [weak connection] frame in
            if frame.opcode == .ping {
                connection?.simulate(.pong(nil))
            }
        }

        harness.connect()

        for _ in 0 ..< 2 {
            harness.engine.didTrigger(scheduler: harness.engine.pingScheduler)
            harness.drain()
        }

        harness.engine.didTrigger(scheduler: harness.engine.pongTimeoutScheduler)
        harness.drain()

        #expect(connection.pingCount == 2)
        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("inbound traffic keeps the connection alive without pongs")
    func inboundTrafficSatisfiesPongTimeout() {
        let harness = Harness(pongTimeout: 60)

        let connection = harness.transport
        connection.onFrame = { [weak connection] frame in
            if frame.opcode == .ping {
                connection?.simulateText("{\"jsonrpc\":\"2.0\",\"method\":\"noop\",\"params\":{}}")
            }
        }

        harness.connect()

        harness.engine.didTrigger(scheduler: harness.engine.pingScheduler)
        harness.drain()

        harness.engine.didTrigger(scheduler: harness.engine.pongTimeoutScheduler)
        harness.drain()

        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.state == .connected(url: Self.url))
    }
}


/// A reconnect always makes the engine request a fresh transport from the factory.
/// Event-driven flows are verified deterministically: `drain()` flushes the serial
/// processing queue, and scheduler fires are injected via `didTrigger`. Only the two
/// real-timer tests await wall-clock with a generous ceiling.
private final class Harness {
    let engine: WebSocketEngine
    let delegate = MockWebSocketEngineDelegate()
    let factory = MockWebSocketConnectionFactory()
    let queue = DispatchQueue(label: "test.ws.reconnect")

    var transport: MockWebSocketTransport { factory.latest }

    init(
        pingInterval: TimeInterval = 0,
        pongTimeout: TimeInterval = 0.1,
        viabilityTimeout: TimeInterval = 0.1
    ) {
        engine = WebSocketEngine(
            urls: [WebSocketEngineReconnectTests.url],
            connectionFactory: factory,
            reachabilityManager: nil,
            reconnectionStrategy: StubReconnectionStrategy(delay: 1000),
            processingQueue: queue,
            autoconnect: true,
            pingInterval: pingInterval,
            pongTimeout: pongTimeout,
            viabilityTimeout: viabilityTimeout,
            name: "test"
        )!
        engine.delegate = delegate
    }

    func drain() {
        for _ in 0 ..< 4 { queue.sync {} }
    }

    func connect() {
        transport.simulateConnected()
        drain()
    }

    @discardableResult
    func submitNonResendableRequest() throws -> UInt16 {
        try engine.callMethod(
            "author_submitExtrinsic",
            params: ["0x00"],
            options: JSONRPCOptions(resendOnReconnect: false)
        ) { (_: Result<String, Error>) in }
    }

    func respond(to requestId: UInt16) {
        transport.simulateText("{\"jsonrpc\":\"2.0\",\"result\":\"0x00\",\"id\":\(requestId)}")
        drain()
    }

    func transportCount() -> Int {
        var count = 0
        queue.sync { count = factory.transports.count }
        return count
    }

    func reconnectHappened(within timeout: TimeInterval = 2) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if transportCount() >= 2 {
                return true
            }

            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        return transportCount() >= 2
    }
}
