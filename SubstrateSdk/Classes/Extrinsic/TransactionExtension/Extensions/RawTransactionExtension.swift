import Foundation

public struct RawTransactionExtension: TransactionExtending {
    public let txExtensionId: String
    public let rawImplicit: Data?
    public let decodedExplicit: JSON?
    public let coder: TransactionExtensionCoding

    public init(
        txExtensionId: String,
        rawImplicit: Data?,
        decodedExplicit: JSON?,
        coder: TransactionExtensionCoding
    ) {
        self.txExtensionId = txExtensionId
        self.rawImplicit = rawImplicit
        self.decodedExplicit = decodedExplicit
        self.coder = coder
    }

    public func implicit(
        using _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> Data? {
        guard let rawImplicit, !rawImplicit.isEmpty else {
            return nil
        }

        return rawImplicit
    }

    public func explicit(
        for _: TransactionExtension.Implication,
        encodingFactory _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        guard let json = decodedExplicit else { return nil }

        return TransactionExtension.Explicit(
            extensionId: txExtensionId,
            value: json,
            customEncoder: coder
        )
    }
}
