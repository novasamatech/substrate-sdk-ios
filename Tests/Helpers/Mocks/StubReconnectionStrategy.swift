import Foundation
import SubstrateSdk

/// Reconnection strategy returning a fixed delay (or `nil` to make the engine give up),
/// so tests don't depend on wall-clock backoff timing.
public struct StubReconnectionStrategy: ReconnectionStrategyProtocol {
    public let delay: TimeInterval?

    public init(delay: TimeInterval?) {
        self.delay = delay
    }

    public func reconnectAfter(attempt _: Int) -> TimeInterval? {
        delay
    }
}
