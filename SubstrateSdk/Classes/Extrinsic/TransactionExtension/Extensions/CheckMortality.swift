import Foundation

public extension TransactionExtension {
    struct CheckMortality: Codable, TransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.mortality }
        
        public let era: Era
        public let blockHash: String
        
        public init(era: Era, blockHash: String) {
            self.era = era
            self.blockHash = blockHash
        }
        
        public func implicit(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> Data? {
            let encoder = encodingFactory.createEncoder()
            try encoder.appendBytes(json: .stringValue(blockHash))
            return try encoder.encode()
        }
        
        public func explicit(
            for implication: TransactionExtension.Implication,
            encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> TransactionExtension.Explicit? {
            let value = try era.toScaleCompatibleJSON(with: context?.toRawContext())
            
            return TransactionExtension.Explicit(
                extensionId: txExtensionId,
                value: value,
                customEncoder: DefaultTransactionExtensionCoder(
                    txExtensionId: txExtensionId,
                    extensionExplicitType: GenericType.era.name
                )
            )
        }
    }
}
