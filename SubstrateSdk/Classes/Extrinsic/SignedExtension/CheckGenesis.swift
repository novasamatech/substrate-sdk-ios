import Foundation

public extension ExtrinsicSignedExtension {
    struct CheckGenesis: Codable, OnlyExtrinsicSignatureExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.genesis }
        
        public let genesisHash: String
        
        public init(genesisHash: String) {
            self.genesisHash = genesisHash
        }
        
        public func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws {
            try encoder.appendBytes(json: .stringValue(genesisHash))
        }
    }
}
