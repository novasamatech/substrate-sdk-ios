import Foundation

public extension ExtrinsicSignedExtension {
    struct  CheckNonce: Codable, OnlyExtrinsicSignedExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.nonce.rawValue }
        
        public let nonce: UInt32
        
        public init(nonce: UInt32) {
            self.nonce = nonce
        }
        
        public func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) throws {
            extraStore[signedExtensionId] = try StringScaleMapper(value: nonce).toScaleCompatibleJSON(with: context)
        }
    }
}
