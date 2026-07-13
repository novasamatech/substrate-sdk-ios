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

    @Test("viability recovery within the grace period keeps the connection")
    func viabilityRecoveryKeepsConnection() async {
        let harness = Harness()

        harness.connect()
        harness.transport.simulate(.viabilityChanged(false))
        harness.transport.simulate(.viabilityChanged(true))

        let didReconnect = await harness.reconnectHappened(within: 0.5)
        #expect(!didReconnect)

        harness.drain()
        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("better path suggestion reconnects immediately when idle")
    func betterPathTriggersImmediateReconnect() async {
        let harness = Harness()

        harness.connect()
        harness.transport.simulate(.reconnectSuggested(true))

        let didReconnect = await harness.reconnectHappened()
        #expect(didReconnect)

        harness.drain()
        #expect(harness.factory.transports.count == 2)
        #expect(harness.factory.latest.startCount == 1)
    }

    @Test("better path waits for a non-resendable in-flight request")
    func betterPathWaitsForInFlight() async throws {
        let harness = Harness()

        harness.connect()

        let requestId = try harness.submitNonResendableRequest()
        harness.drain()

        harness.transport.simulate(.reconnectSuggested(true))

        let reconnectedEarly = await harness.reconnectHappened(within: 0.5)
        #expect(!reconnectedEarly)

        harness.drain()
        #expect(harness.engine.pendingBetterPathReconnect)

        harness.respond(to: requestId)

        let didReconnect = await harness.reconnectHappened()
        #expect(didReconnect)

        harness.drain()
        #expect(!harness.engine.pendingBetterPathReconnect)
        #expect(harness.factory.transports.count == 2)
    }

    @Test("withdrawn better path suggestion cancels the deferred reconnect")
    func withdrawnBetterPathCancelsDeferredReconnect() async throws {
        let harness = Harness()

        harness.connect()

        let requestId = try harness.submitNonResendableRequest()
        harness.drain()

        harness.transport.simulate(.reconnectSuggested(true))
        harness.transport.simulate(.reconnectSuggested(false))

        harness.respond(to: requestId)

        let didReconnect = await harness.reconnectHappened(within: 0.5)
        #expect(!didReconnect)

        harness.drain()
        #expect(harness.factory.transports.count == 1)
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

        let reconnectedAgain = await harness.transportCountReached(3, within: 0.5)
        #expect(!reconnectedAgain)

        harness.drain()
        #expect(harness.engine.state == .connected(url: Self.url))
    }

    @Test("late pong timeout after pong received does not restart the connection")
    func latePongTimeoutAfterPongIsIgnored() async {
        let harness = Harness(pongTimeout: 5)

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

    @Test("late viability timeout after recovery does not restart the connection")
    func lateViabilityTimeoutAfterRecoveryIsIgnored() async {
        let harness = Harness(viabilityTimeout: 5)

        harness.connect()

        harness.transport.simulate(.viabilityChanged(false))
        harness.transport.simulate(.viabilityChanged(true))
        harness.drain()

        harness.engine.didTrigger(scheduler: harness.engine.viabilityTimeoutScheduler)
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
    func pongReceptionKeepsConnectionAlive() async {
        let harness = Harness(pingInterval: 0.1, pongTimeout: 0.3)

        let connection = harness.transport
        connection.onFrame = { [weak connection] frame in
            if frame.opcode == .ping {
                connection?.simulate(.pong(nil))
            }
        }

        harness.connect()

        let didReconnect = await harness.reconnectHappened(within: 1)
        #expect(!didReconnect)

        harness.drain()
        #expect(connection.pingCount >= 2)
        #expect(harness.factory.transports.count == 1)
        #expect(harness.engine.state == .connected(url: Self.url))
    }
}


/// A reconnect always makes the engine request a fresh transport from the factory,
/// so tests detect it by polling the number of created transports.
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
            "extrinsic",
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

    func transportCountReached(_ expected: Int, within timeout: TimeInterval = 2) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if transportCount() >= expected {
                return true
            }

            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        return transportCount() >= expected
    }

    func reconnectHappened(within timeout: TimeInterval = 2) async -> Bool {
        await transportCountReached(2, within: timeout)
    }
}
