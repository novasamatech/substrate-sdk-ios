import Foundation
import BigInt

public class ChargeAssetTxPayment: Codable, ExtrinsicExtension {
    public static let name: String = "ChargeAssetTxPayment"

    @StringCodable public var tip: BigUInt
    @OptionStringCodable public var assetId: UInt32?

    public init(tip: BigUInt = 0, assetId: UInt32? = nil) {
        self.tip = tip
        self.assetId = assetId
    }
}
