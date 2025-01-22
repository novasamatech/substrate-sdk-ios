import Foundation
import BigInt

public extension TransactionExtension {
    struct ChargeAssetTxPayment: Codable, OnlyExplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.assetTxPayment }

        @StringCodable public var tip: BigUInt
        @OptionStringCodable public var assetId: UInt32?

        public init(tip: BigUInt = 0, assetId: UInt32? = nil) {
            self.tip = tip
            self.assetId = assetId
        }
    }
}
