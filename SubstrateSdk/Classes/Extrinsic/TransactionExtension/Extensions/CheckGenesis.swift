import Foundation

public extension TransactionExtension {
    struct CheckGenesis: Codable, OnlyImplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.genesis }

        public let genesisHash: String

        public init(genesisHash: String) {
            self.genesisHash = genesisHash
        }

        public func implicit(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata _: RuntimeMetadataProtocol,
            context _: RuntimeJsonContext?
        ) throws -> Data? {
            let encoder = encodingFactory.createEncoder()

            try encoder.appendBytes(json: .stringValue(genesisHash))

            return try encoder.encode()
        }
    }
}
