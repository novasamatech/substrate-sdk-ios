import Foundation

public extension ExtrinsicSignedExtension {
    struct CheckMortality: Codable, ExtrinsicSignedExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.mortality }
        
        public let era: Era
        public let blockHash: String
        
        public init(era: Era, blockHash: String) {
            self.era = era
            self.blockHash = blockHash
        }
        
        public func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) throws {
            extraStore[signedExtensionId] = try era.toScaleCompatibleJSON(with: context)
        }
        
        public func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws {
            try encoder.appendBytes(json: .stringValue(blockHash))
        }
    }
}
