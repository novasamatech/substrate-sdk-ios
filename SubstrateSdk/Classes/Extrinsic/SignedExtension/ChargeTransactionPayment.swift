import Foundation
import BigInt

public extension ExtrinsicSignedExtension {
    struct ChargeTransactionPayment: Codable, OnlyExtrinsicSignedExtending {
        public static let name: String { Extrinsic.SignedExtensionId.txPayment.rawValue }

        @StringCodable public var tip: BigUInt

        public init(tip: BigUInt = 0) {
            self.tip = tip
        }
    }
}
