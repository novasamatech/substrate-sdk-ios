import Foundation
import BigInt

public class AssetConversionTxPayment<AssetId: Codable>: Codable, OnlyExplicitTransactionExtending {
    public var txExtensionId: String { "ChargeAssetTxPayment" }

    @StringCodable public var tip: BigUInt
    let assetId: AssetId?

    public init(tip: BigUInt = 0, assetId: AssetId? = nil) {
        self.tip = tip
        self.assetId = assetId
    }
}
