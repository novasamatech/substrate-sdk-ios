import Foundation
import SubstrateSdk

/// Records `WebSocketEngine` delegate callbacks for assertions.
public final class MockWebSocketEngineDelegate: WebSocketEngineDelegate {
    public private(set) var stateTransitions: [(from: WebSocketEngine.State, to: WebSocketEngine.State)] = []
    public private(set) var switchedURLs: [URL] = []

    public init() {}

    public func webSocketDidChangeState(
        _: AnyObject,
        from oldState: WebSocketEngine.State,
        to newState: WebSocketEngine.State
    ) {
        stateTransitions.append((oldState, newState))
    }

    public func webSocketDidSwitchURL(_: AnyObject, newUrl: URL) {
        switchedURLs.append(newUrl)
    }
}
