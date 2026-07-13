import Foundation
import Starscream

/// Mock of Starscream's low-level `Engine` (the transport that backs a real `WebSocket`).
///
/// This is the *proper* seam for testing anything built on a Starscream `WebSocket`:
/// a genuine `WebSocket` is constructed around this transport (see
/// `MockWebSocketConnectionFactory`), so the code under test talks to the real
/// `WebSocket` while this mock records outbound I/O and lets the test push inbound
/// events as if they came off the wire.
public final class MockWebSocketTransport: Engine {
    public struct Frame: Equatable {
        public let data: Data
        public let opcode: FrameOpCode
    }

    /// The close code Starscream uses for a graceful "going away" disconnect.
    public static let goingAwayCloseCode = CloseCode.goingAway.rawValue

    // Set by the owning `WebSocket` in `connect()`; it's the real `WebSocket` instance.
    private weak var delegate: EngineDelegate?

    public private(set) var startCount = 0
    public private(set) var forceStopCount = 0
    public private(set) var stopCloseCodes: [UInt16] = []
    public private(set) var sentFrames: [Frame] = []
    public private(set) var sentStrings: [String] = []

    public init() {}

    /// JSON-RPC payloads the SDK wrote (text frames).
    public var sentRequests: [Data] { sentFrames.filter { $0.opcode == .textFrame }.map(\.data) }
    public var pingCount: Int { sentFrames.filter { $0.opcode == .ping }.count }
    public var pongCount: Int { sentFrames.filter { $0.opcode == .pong }.count }

    // MARK: Engine

    public func register(delegate: EngineDelegate) { self.delegate = delegate }
    public func start(request _: URLRequest) { startCount += 1 }
    public func stop(closeCode: UInt16) { stopCloseCodes.append(closeCode) }
    public func forceStop() { forceStopCount += 1 }

    public var onFrame: ((Frame) -> Void)?

    public func write(data: Data, opcode: FrameOpCode, completion: (() -> Void)?) {
        let frame = Frame(data: data, opcode: opcode)
        sentFrames.append(frame)
        completion?()
        onFrame?(frame)
    }

    public func write(string: String, completion: (() -> Void)?) {
        sentStrings.append(string)
        completion?()
    }

    // MARK: Driving inbound events

    /// Push an event as if received from the network. The owning `WebSocket` forwards it
    /// to its `WebSocketDelegate` on its `callbackQueue`, exactly as in production.
    public func simulate(_ event: WebSocketEvent) { delegate?.didReceive(event: event) }

    public func simulateConnected() { simulate(.connected([:])) }
    public func simulateText(_ string: String) { simulate(.text(string)) }
    public func simulateBinary(_ data: Data) { simulate(.binary(data)) }
    public func simulateDisconnected(
        reason: String = "closed",
        code: UInt16 = MockWebSocketTransport.goingAwayCloseCode
    ) { simulate(.disconnected(reason, code)) }
    public func simulatePing(_ data: Data = Data()) { simulate(.ping(data)) }
    public func simulateError(_ error: Error?) { simulate(.error(error)) }
    public func simulateCancelled() { simulate(.cancelled) }
}
