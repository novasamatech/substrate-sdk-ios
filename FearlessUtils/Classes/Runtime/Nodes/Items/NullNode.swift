import Foundation

public struct NullNode: Node {
    public var typeName: String { GenericType.null.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {}
    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        return .null
    }
}
