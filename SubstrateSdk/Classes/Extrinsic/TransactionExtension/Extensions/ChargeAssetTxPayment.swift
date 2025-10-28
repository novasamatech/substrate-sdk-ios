import Foundation
import BigInt

public extension TransactionExtension {
    class ChargeAssetTxPayment<AssetId: Codable>: Codable, OnlyExplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.assetTxPayment }

        @StringCodable public var tip: BigUInt
        @NullCodable public var assetId: AssetId?

        public init(tip: BigUInt = 0, assetId: AssetId? = nil) {
            self.tip = tip
            self.assetId = assetId
        }
    }
}
