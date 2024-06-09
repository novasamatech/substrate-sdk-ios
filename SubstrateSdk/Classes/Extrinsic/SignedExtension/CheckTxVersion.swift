import Foundation

public extension ExtrinsicSignedExtension {
    struct CheckTxVersion: Codable, OnlyExtrinsicSignatureExtending {
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.txVersion }
        
        public let transactionVersion: UInt32
        
        public init(transactionVersion: UInt32) {
            self.transactionVersion = transactionVersion
        }
        
        public func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws {
            try encoder.append(encodable: transactionVersion)
        }
    }
}
