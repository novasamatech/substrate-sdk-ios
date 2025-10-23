import Foundation
import SubstrateSdk

public struct BatchStorageSubscriptionRequest {
    public let innerRequest: SubscriptionRequestProtocol
    public let mappingKey: String?
    
    public init(innerRequest: SubscriptionRequestProtocol, mappingKey: String?) {
        self.innerRequest = innerRequest
        self.mappingKey = mappingKey
    }
}

public struct BatchStorageSubscriptionResultValue {
    public let mappingKey: String?
    public let value: JSON
    
    public init(mappingKey: String?, value: JSON) {
        self.mappingKey = mappingKey
        self.value = value
    }
}

public protocol BatchStorageSubscriptionResult {
    init(
        values: [BatchStorageSubscriptionResultValue],
        blockHashJson: JSON,
        context: [CodingUserInfoKey: Any]?
    ) throws
}

public struct BatchStorageSubscriptionRawResult: BatchStorageSubscriptionResult {
    public let values: [BatchStorageSubscriptionResultValue]
    public let blockHashJson: JSON

    public init(
        values: [BatchStorageSubscriptionResultValue],
        blockHashJson: JSON,
        context _: [CodingUserInfoKey: Any]?
    ) throws {
        self.values = values
        self.blockHashJson = blockHashJson
    }
}
