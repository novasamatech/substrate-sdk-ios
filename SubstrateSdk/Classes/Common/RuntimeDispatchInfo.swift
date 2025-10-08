import Foundation
import BigInt

public struct RuntimeDispatchInfo: Decodable {
    public enum CodingKeys: String, CodingKey {
        case fee = "partialFee"
        case weight
    }

    public let fee: String
    @Substrate.WeightDecodable
    public var weight: Substrate.WeightV2

    public init(fee: String, weight: Substrate.WeightV2) {
        self.fee = fee
        _weight = .init(wrappedValue: weight)
    }
}
