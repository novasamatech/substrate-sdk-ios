import Foundation

public enum ExtrinsicExtraNodeError: Error {
    case invalidParams
}

public class ExtrinsicExtraNode: Node {
    public var typeName: String { GenericType.extrinsicExtra.name }
    public let runtimeMetadata: RuntimeMetadataProtocol
    public let customExtensions: [ExtrinsicExtensionCoder]

    public init(runtimeMetadata: RuntimeMetadataProtocol, customExtensions: [ExtrinsicExtensionCoder]) {
        self.runtimeMetadata = runtimeMetadata
        self.customExtensions = customExtensions
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        for checkString in runtimeMetadata.getSignedExtensions() {
            let check = ExtrinsicCheck(rawValue: checkString)

            switch check {
            case .mortality:
                guard let era = params[KnownExtrinsicExtraKey.era] else {
                    throw ExtrinsicExtraNodeError.invalidParams
                }

                try encoder.append(json: era, type: GenericType.era.name)
            case .nonce:
                guard let nonce = params[KnownExtrinsicExtraKey.nonce] else {
                    throw ExtrinsicExtraNodeError.invalidParams
                }

                try encoder.appendCompact(json: nonce, type: KnownType.index.name)
            case .txPayment:
                guard let tip = params[KnownExtrinsicExtraKey.tip] else {
                    throw ExtrinsicExtraNodeError.invalidParams
                }

                try encoder.appendCompact(json: tip, type: KnownType.balance.name)
            default:
                if let customExtension = customExtensions.first(where: { $0.name == checkString }) {
                    try customExtension.encodeAdditionalExtra(from: params, encoder: encoder)
                }
            }
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let extra = try runtimeMetadata.getSignedExtensions().reduce(into: [String: JSON]()) { (result, item) in
                let check = ExtrinsicCheck(rawValue: item)

                switch check {
                case .mortality:
                    let era = try decoder.read(type: GenericType.era.rawValue)
                    result[KnownExtrinsicExtraKey.era] = era
                case .nonce:
                    let nonce = try decoder.readCompact(type: KnownType.index.rawValue)
                    result[KnownExtrinsicExtraKey.nonce] = nonce
                case .txPayment:
                    let tip = try decoder.readCompact(type: KnownType.balance.rawValue)
                    result[KnownExtrinsicExtraKey.tip] = tip
                default:
                    if let customExtension = customExtensions.first(where: { $0.name == item }) {
                        try customExtension.decodeAdditionalExtra(to: &result, decoder: decoder)
                    }
                }
        }

        return .dictionaryValue(extra)
    }
}
