import Foundation

open class DefaultExtrinsicSignedExtensionCoder: ExtrinsicSignedExtensionCoding {
    public let signedExtensionId: String
    public let extraType: String

    public init(signedExtensionId: String, extraType: String) {
        self.signedExtensionId = signedExtensionId
        self.extraType = extraType
    }

    public func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let json = try decoder.read(type: extraType)

        extraStore[signedExtensionId] = json
    }

    public func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let json = extra[signedExtensionId] else {
            return
        }

        try encoder.append(json: json, type: extraType)
    }
}

open class CompactExtrinsicSignedExtensionCoder: ExtrinsicSignedExtensionCoding {
    public let signedExtensionId: String
    public let extraType: String

    public init(signedExtensionId: String, extraType: String) {
        self.signedExtensionId = signedExtensionId
        self.extraType = extraType
    }

    public func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let json = try decoder.readCompact(type: extraType)

        extraStore[signedExtensionId] = json
    }

    public func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let json = extra[signedExtensionId] else {
            return
        }

        try encoder.appendCompact(json: json, type: extraType)
    }
}
