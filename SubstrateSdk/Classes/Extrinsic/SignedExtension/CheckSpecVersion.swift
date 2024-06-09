import Foundation

public extension ExtrinsicSignedExtension {
    struct CheckSpecVersion: Codable, OnlyExtrinsicSignatureExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.specVersion }
        
        public let specVersion: UInt32
        
        public init(specVersion: UInt32) {
            self.specVersion = specVersion
        }
        
        public func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws {
            try encoder.append(encodable: specVersion)
        }
    }
}
