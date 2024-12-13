import Foundation

public extension TransactionExtension {
    struct  CheckNonce: Codable, OnlyExplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.nonce }
        
        public let nonce: UInt32
        
        public init(nonce: UInt32) {
            self.nonce = nonce
        }
        
        public func explicit(
            for implication: TransactionExtension.Implication,
            encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> TransactionExtension.Explicit? {
            let value = try StringScaleMapper(value: nonce).toScaleCompatibleJSON(with: context?.toRawContext())
            
            return TransactionExtension.Explicit(
                extensionId: txExtensionId,
                value: value,
                customEncoder: Self.getTransactionExtensionCoder()
            )
        }
        
        public static func getTransactionExtensionCoder() -> TransactionExtensionCoding {
            CompactTransactionExtensionCoder(
                txExtensionId: Extrinsic.TransactionExtensionId.nonce,
                extensionExplicitType: KnownType.index.name
            )
        }
    }
}
