import Foundation

public struct OpaqueCallNode: Node {
    public var typeName: String { "OpaqueCall" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {

    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        .null
    }
}
