import Foundation

public struct CheckNonceNode: Node {
    public var typeName: String { "CheckNonce" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 1 else {
            throw DynamicScaleCoderError.invalidParams
        }

        try encoder.appendCompact(json: params[0], type: "Index")
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let nonce = try decoder.readCompact(type: "Index")

        return .arrayValue([nonce])
    }
}
