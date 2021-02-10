import Foundation

public struct CheckWeightNode: Node {
    public var typeName: String { "CheckWeight" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 0 else {
            throw DynamicScaleCoderError.invalidParams
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        return .arrayValue([])
    }
}
