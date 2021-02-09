import Foundation

public struct GenericCallNode: Node {
    public var typeName: String { "GenericCall" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {

    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        .null
    }
}
