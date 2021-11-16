import Foundation
import Starscream

public protocol WebSocketConnectionFactoryProtocol {
    func createConnection(
        for url: URL,
        processingQueue: DispatchQueue,
        connectionTimeout: TimeInterval
    ) -> WebSocketConnectionProtocol
}

open class WebSocketConnectionFactory: WebSocketConnectionFactoryProtocol {
    public init() {}

    public func createConnection(
        for url: URL,
        processingQueue: DispatchQueue,
        connectionTimeout: TimeInterval
    ) -> WebSocketConnectionProtocol {
        let request = URLRequest(url: url, timeoutInterval: connectionTimeout)

        let engine = WSEngine(
            transport: FoundationTransport(),
            certPinner: FoundationSecurity(),
            compressionHandler: nil
        )

        let connection = WebSocket(request: request, engine: engine)
        connection.callbackQueue = processingQueue

        return connection
    }
}
