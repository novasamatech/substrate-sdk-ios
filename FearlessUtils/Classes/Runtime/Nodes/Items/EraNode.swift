import Foundation

public struct EraNode: Node {
    public var typeName: String { GenericType.era.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        let era = try value.map(to: Era.self)
        try encoder.append(encodable: era)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let era: Era = try decoder.read() else {
            return .null
        }

        return try era.toScaleCompatibleJSON()
    }
}
