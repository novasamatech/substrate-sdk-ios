import Foundation

public struct CheckNonceNode: Node {
    public var typeName: String { "CheckNonce" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 1 else {
            throw DynamicScaleCoderError.invalidParams
        }

        try encoder.appendCompact(json: params[0], type: KnownType.index.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let nonce = try decoder.readCompact(type: KnownType.index.name)

        return .arrayValue([nonce])
    }
}
