import Foundation
import BigInt

public class ChargeAssetTxPayment<A: Codable>: Codable, OnlyExtrinsicSignedExtending {
    public static let name: String { Extrinsic.SignedExtensionId.assetTxPayment.rawValue }

    @StringCodable public var tip: BigUInt
    public let assetId: A?

    public init(tip: BigUInt = 0, assetId: A? = nil) {
        self.tip = tip
        self.assetId = assetId
    }
}
