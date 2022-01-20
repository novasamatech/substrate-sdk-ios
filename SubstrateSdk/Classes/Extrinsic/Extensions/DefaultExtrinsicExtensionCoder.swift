import Foundation

open class DefaultExtrinsicExtensionCoder: ExtrinsicExtensionCoder {
    public let name: String
    public let extraType: String

    public init(name: String, extraType: String) {
        self.name = name
        self.extraType = extraType
    }

    public func decodeAdditionalExtra(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let json = try decoder.read(type: extraType)

        extraStore[name] = json
    }

    public func encodeAdditionalExtra(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let json = extra[name] else {
            return
        }

        try encoder.append(json: json, type: extraType)
    }
}
