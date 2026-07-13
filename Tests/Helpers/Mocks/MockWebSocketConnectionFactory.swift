import Foundation
import Starscream
import SubstrateSdk

/// `WebSocketConnectionFactoryProtocol` that hands the SDK a **real** Starscream `WebSocket`
/// backed by a `MockWebSocketTransport`. Every connection the SDK creates (initial connect,
/// reconnect, node switch) is recorded so tests can inspect or drive the current one via
/// `latest`.
public final class MockWebSocketConnectionFactory: WebSocketConnectionFactoryProtocol {
    public private(set) var transports: [MockWebSocketTransport] = []

    /// The transport backing the SDK's current connection.
    public var latest: MockWebSocketTransport {
        guard let transport = transports.last else {
            fatalError("No connection has been created yet")
        }

        return transport
    }

    public var onCreateConnection: ((MockWebSocketTransport) -> Void)?

    public init() {}

    public func createConnection(
        for url: URL,
        processingQueue: DispatchQueue,
        connectionTimeout: TimeInterval
    ) -> WebSocketConnectionProtocol {
        let transport = MockWebSocketTransport()
        transports.append(transport)
        onCreateConnection?(transport)

        let request = URLRequest(url: url, timeoutInterval: connectionTimeout)
        let socket = WebSocket(request: request, engine: transport)
        socket.callbackQueue = processingQueue

        return socket
    }
}
