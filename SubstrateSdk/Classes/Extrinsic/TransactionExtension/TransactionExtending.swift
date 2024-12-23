import Foundation

public protocol TransactionExtending {
    var txExtensionId: String { get }

    func implicit(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> Data?

    func explicit(
        for implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit?
}

public protocol OnlyExplicitTransactionExtending: TransactionExtending {}

public extension OnlyExplicitTransactionExtending {
    func implicit(
        using _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> Data? {
        nil
    }
}

public extension OnlyExplicitTransactionExtending where Self: Codable {
    func explicit(
        for _: TransactionExtension.Implication,
        encodingFactory _: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        let value = try toScaleCompatibleJSON(with: context?.toRawContext())

        return try TransactionExtension.Explicit(
            from: value,
            txExtensionId: txExtensionId,
            metadata: metadata
        )
    }
}

public protocol OnlyImplicitTransactionExtending: TransactionExtending {}

public extension OnlyImplicitTransactionExtending {
    func explicit(
        for _: TransactionExtension.Implication,
        encodingFactory _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        nil
    }
}

public protocol TransactionExtensionCoding: AnyObject {
    var txExtensionId: String { get }

    func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws
    func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws
}
