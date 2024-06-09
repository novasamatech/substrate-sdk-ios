import Foundation
import BigInt

public extension ExtrinsicSignedExtension {
    struct ChargeTransactionPayment: Codable, OnlyExtrinsicSignedExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.txPayment.rawValue }

        public let tip: BigUInt

        public init(tip: BigUInt = 0) {
            self.tip = tip
        }
        
        public func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) throws {
            extraStore[signedExtensionId] = try StringScaleMapper(value: tip).toScaleCompatibleJSON(with: context)
        }
    }
}
