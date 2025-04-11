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
            metadata _: RuntimeMetadataProtocol,
            context _: RuntimeJsonContext?
        ) throws -> Data? {
            let encoder = encodingFactory.createEncoder()
            try encoder.appendBytes(json: .stringValue(blockHash))
            return try encoder.encode()
        }

        public func explicit(
            for _: TransactionExtension.Implication,
            encodingFactory _: DynamicScaleEncodingFactoryProtocol,
            metadata _: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> TransactionExtension.Explicit? {
            let value = try era.toScaleCompatibleJSON(with: context?.toRawContext())

            return TransactionExtension.Explicit(
                extensionId: txExtensionId,
                value: value,
                customEncoder: Self.getTransactionExtensionCoder()
            )
        }

        public static func getTransactionExtensionCoder() -> TransactionExtensionCoding {
            DefaultTransactionExtensionCoder(
                txExtensionId: Extrinsic.TransactionExtensionId.mortality,
                extensionExplicitType: GenericType.era.name
            )
        }
    }
}
