import Foundation

public enum ExtrinsicSignatureNodeError: Error {
    case invalidParams
}

public struct ExtrinsicSignatureNode: Node {
    public var typeName: String { GenericType.extrinsicSignature.name }
    public let runtimeMetadata: RuntimeMetadata

    public init(runtimeMetadata: RuntimeMetadata) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        guard
            let address = params[ExtrinsicSignature.CodingKeys.address.rawValue],
            let signature = params[ExtrinsicSignature.CodingKeys.signature.rawValue],
            let extra = params[ExtrinsicSignature.CodingKeys.extra.rawValue] else {
            throw ExtrinsicSignatureNodeError.invalidParams
        }

        try encoder.append(json: address, type: KnownType.address.name)
        try encoder.append(json: signature, type: KnownType.signature.name)
        try encoder.append(json: extra, type: GenericType.extrinsicExtra.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let address = try decoder.read(type: KnownType.address.name)
        let signature = try decoder.read(type: KnownType.signature.name)
        let extra = try decoder.read(type: GenericType.extrinsicExtra.name)

        return .dictionaryValue([
            ExtrinsicSignature.CodingKeys.address.rawValue: address,
            ExtrinsicSignature.CodingKeys.signature.rawValue: signature,
            ExtrinsicSignature.CodingKeys.extra.rawValue: extra
        ])
    }
}
