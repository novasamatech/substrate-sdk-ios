import Foundation

public extension TransactionExtension {
    struct CheckSpecVersion: Codable, OnlyImplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.specVersion }
        
        public let specVersion: UInt32
        
        public init(specVersion: UInt32) {
            self.specVersion = specVersion
        }
        
        public func implicit(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> Data? {
            let encoder = encodingFactory.createEncoder()
            try encoder.append(encodable: specVersion)
            return try encoder.encode()
        }
    }
}
