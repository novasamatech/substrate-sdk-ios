import Foundation

public enum ExtrinsicExtraNodeError: Error {
    case invalidParams
}

public class ExtrinsicExtraNode: Node {
    static let defaultExtensions: [TransactionExtensionCoding] = [
        TransactionExtension.CheckMortality.getTransactionExtensionCoder(),
        TransactionExtension.CheckNonce.getTransactionExtensionCoder(),
        TransactionExtension.ChargeTransactionPayment.getTransactionExtensionCoder(),
        CheckMetadataHashCoder()
    ]

    public var typeName: String { GenericType.extrinsicExtra.name }
    public let runtimeMetadata: RuntimeMetadataProtocol
    public let customExtensions: [TransactionExtensionCoding]

    public init(
        runtimeMetadata: RuntimeMetadataProtocol,
        customExtensions: [TransactionExtensionCoding]
    ) {
        self.runtimeMetadata = runtimeMetadata
        self.customExtensions = customExtensions
    }

    private func getCoders() -> [String: TransactionExtensionCoding] {
        (Self.defaultExtensions + customExtensions).reduce(into: [String: TransactionExtensionCoding]()) {
            $0[$1.txExtensionId] = $1
        }
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        try encode(params, extensionVersion: ExtrinsicConstants.defaultExtensionVersion, encoder: encoder)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let extra = try decode(extensionVersion: ExtrinsicConstants.defaultExtensionVersion, decoder: decoder)

        return .dictionaryValue(extra)
    }

    public func encode(
        _ extra: ExtrinsicExtra,
        extensionVersion: UInt8,
        encoder: DynamicScaleEncoding
    ) throws {
        let coders = getCoders()

        for extensionId in try runtimeMetadata.getSignedExtensions(forExtensionVersion: extensionVersion) {
            if let coder = coders[extensionId] {
                try coder.encodeIncludedInExtrinsic(from: extra, encoder: encoder)
                continue
            }

            guard let type = try runtimeMetadata.getSignedExtensionType(
                for: extensionId,
                extensionVersion: extensionVersion
            ) else {
                continue
            }

            if let extensionParams = extra[extensionId] {
                try encoder.append(json: extensionParams, type: type)
            } else if encoder.canEncodeOptional(for: type) {
                try encoder.append(json: JSON.null, type: type)
            }
        }
    }

    public func decode(extensionVersion: UInt8, decoder: DynamicScaleDecoding) throws -> ExtrinsicExtra {
        let coders = getCoders()

        return try runtimeMetadata.getSignedExtensions(forExtensionVersion: extensionVersion).reduce(
            into: ExtrinsicExtra()
        ) { result, extensionId in
            if let coder = coders[extensionId] {
                try coder.decodeIncludedInExtrinsic(to: &result, decoder: decoder)
            } else if let type = try runtimeMetadata.getSignedExtensionType(
                for: extensionId,
                extensionVersion: extensionVersion
            ) {
                result[extensionId] = try decoder.read(type: type)
            }
        }
    }
}
