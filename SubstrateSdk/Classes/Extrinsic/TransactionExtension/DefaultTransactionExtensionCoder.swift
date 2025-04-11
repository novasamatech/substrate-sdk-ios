import Foundation

open class DefaultTransactionExtensionCoder: TransactionExtensionCoding {
    public let txExtensionId: String
    public let extensionExplicitType: String

    public init(txExtensionId: String, extensionExplicitType: String) {
        self.txExtensionId = txExtensionId
        self.extensionExplicitType = extensionExplicitType
    }

    public func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let json = try decoder.read(type: extensionExplicitType)

        extraStore[txExtensionId] = json
    }

    public func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let json = extra[txExtensionId] else {
            return
        }

        try encoder.append(json: json, type: extensionExplicitType)
    }
}

open class CompactTransactionExtensionCoder: TransactionExtensionCoding {
    public let txExtensionId: String
    public let extensionExplicitType: String

    public init(txExtensionId: String, extensionExplicitType: String) {
        self.txExtensionId = txExtensionId
        self.extensionExplicitType = extensionExplicitType
    }

    public func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let json = try decoder.readCompact(type: extensionExplicitType)

        extraStore[txExtensionId] = json
    }

    public func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let json = extra[txExtensionId] else {
            return
        }

        try encoder.appendCompact(json: json, type: extensionExplicitType)
    }
}
