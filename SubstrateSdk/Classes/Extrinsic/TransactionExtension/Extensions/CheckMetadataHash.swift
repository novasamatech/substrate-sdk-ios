import Foundation

public extension TransactionExtension {
    struct CheckMetadataHash {
        public enum Mode {
            case enabled(Data)
            case disabled
        }

        public var txExtensionId: String { Extrinsic.TransactionExtensionId.checkMetadataHash }

        public let mode: Mode

        public init(mode: Mode) {
            self.mode = mode
        }
    }
}

extension TransactionExtension.CheckMetadataHash: TransactionExtending {
    public func explicit(
        for _: TransactionExtension.Implication,
        encodingFactory _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        let value: JSON = switch mode {
        case .enabled:
            JSON.stringValue("1")
        case .disabled:
            JSON.stringValue("0")
        }

        return TransactionExtension.Explicit(
            extensionId: txExtensionId,
            value: value,
            customEncoder: CheckMetadataHashCoder()
        )
    }

    public func implicit(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> Data? {
        let encoder = encodingFactory.createEncoder()

        switch mode {
        case let .enabled(data):
            try encoder.appendCommonOption(isNull: false)
            try encoder.appendRawData(data)
        case .disabled:
            try encoder.appendCommonOption(isNull: true)
        }

        return try encoder.encode()
    }
}

public final class CheckMetadataHashCoder: TransactionExtensionCoding {
    public var txExtensionId: String { Extrinsic.TransactionExtensionId.checkMetadataHash }

    public func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let index = extra[txExtensionId] else {
            return
        }

        // the Mode type used for metadata hash is actually a enum but it encoded as u8
        try encoder.appendU8(json: index)
    }

    public func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let isEnabled = try decoder.readU8()
        extraStore[txExtensionId] = isEnabled
    }
}
