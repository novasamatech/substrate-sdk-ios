import Foundation

public extension TransactionExtension {
    struct CheckTxVersion: Codable, OnlyImplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.txVersion }
        
        public let transactionVersion: UInt32
        
        public init(transactionVersion: UInt32) {
            self.transactionVersion = transactionVersion
        }
        
        public func implicit(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> Data? {
            let encoder = encodingFactory.createEncoder()
            try encoder.append(encodable: transactionVersion)
            return try encoder.encode()
        }
    }
}
