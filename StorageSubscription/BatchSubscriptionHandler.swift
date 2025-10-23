import Foundation
import SubstrateSdk

public struct BatchSubscriptionHandler: BatchStorageSubscriptionResult {
    public let blockHash: Data?

    public init(
        values _: [BatchStorageSubscriptionResultValue],
        blockHashJson: JSON,
        context: [CodingUserInfoKey: Any]?
    ) throws {
        blockHash = try blockHashJson.map(to: Data?.self, with: context)
    }
}
