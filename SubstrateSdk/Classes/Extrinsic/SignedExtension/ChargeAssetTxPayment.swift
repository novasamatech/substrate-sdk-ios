import Foundation
import BigInt

public extension ExtrinsicSignedExtension {
    struct ChargeAssetTxPayment: Codable, OnlyExtrinsicSignedExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.assetTxPayment }

        @StringCodable public var tip: BigUInt
        @OptionStringCodable public var assetId: UInt32?

        public init(tip: BigUInt = 0, assetId: UInt32? = nil) {
            self.tip = tip
            self.assetId = assetId
        }
    }
}
