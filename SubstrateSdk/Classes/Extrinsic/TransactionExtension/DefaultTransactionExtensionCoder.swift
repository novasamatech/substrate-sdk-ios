import Foundation

open class DefaultTransactionExtensionCoder: TransactionExtensionCoding {
    public let txExtensionId: String
    public let extensionExplicitType: String

    public init(txExtensionId: String, extensionExplicitType: String) {
        self.txExtensionId = txExtensionId
        self.extensionExplicitType = extensionExplicitType
    }

    public func decodeIncludedInExtrinsic(
        to extraStore: inout ExtrinsicExtra,
        extensionVersion _: UInt8,
        decoder: DynamicScaleDecoding
    ) throws {
        let json = try decoder.read(type: extensionExplicitType)

        extraStore[txExtensionId] = json
    }

    public func encodeIncludedInExtrinsic(
        from extra: ExtrinsicExtra,
        extensionVersion _: UInt8,
        encoder: DynamicScaleEncoding
    ) throws {
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

    public func decodeIncludedInExtrinsic(
        to extraStore: inout ExtrinsicExtra,
        extensionVersion _: UInt8,
        decoder: DynamicScaleDecoding
    ) throws {
        let json = try decoder.readCompact(type: extensionExplicitType)

        extraStore[txExtensionId] = json
    }

    public func encodeIncludedInExtrinsic(
        from extra: ExtrinsicExtra,
        extensionVersion _: UInt8,
        encoder: DynamicScaleEncoding
    ) throws {
        guard let json = extra[txExtensionId] else {
            return
        }

        try encoder.appendCompact(json: json, type: extensionExplicitType)
    }
}

open class DefaultVersionedTransactionExtensionCoder: TransactionExtensionCoding {
    public let txExtensionId: String
    public let metadata: RuntimeMetadataProtocol

    public init(txExtensionId: String, metadata: RuntimeMetadataProtocol) {
        self.txExtensionId = txExtensionId
        self.metadata = metadata
    }

    private func extensionExplicitType(for extensionVersion: UInt8) throws -> String {
        guard let type = try metadata.getSignedExtensionType(
            for: txExtensionId,
            extensionVersion: extensionVersion
        ) else {
            throw TransactionExtensionError.typeNotFound(txExtensionId)
        }

        return type
    }

    public func decodeIncludedInExtrinsic(
        to extraStore: inout ExtrinsicExtra,
        extensionVersion: UInt8,
        decoder: DynamicScaleDecoding
    ) throws {
        let type = try extensionExplicitType(for: extensionVersion)

        extraStore[txExtensionId] = try decoder.read(type: type)
    }

    public func encodeIncludedInExtrinsic(
        from extra: ExtrinsicExtra,
        extensionVersion: UInt8,
        encoder: DynamicScaleEncoding
    ) throws {
        guard let json = extra[txExtensionId] else {
            return
        }

        let type = try extensionExplicitType(for: extensionVersion)

        try encoder.append(json: json, type: type)
    }
}
