import Foundation

public struct CheckMortalityNode: Node {
    public var typeName: String { "CheckMortality" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 1 else {
            throw DynamicScaleCoderError.invalidParams
        }

        try encoder.append(json: params[0], type: GenericType.era.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let era = try decoder.read(type: GenericType.era.name)

        return .arrayValue([era])
    }
}
