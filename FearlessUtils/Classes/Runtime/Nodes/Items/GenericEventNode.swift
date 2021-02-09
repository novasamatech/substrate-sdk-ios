import Foundation

public struct GenericEventNode: Node {
    public var typeName: String { "GenericEvent" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {

    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        .null
    }
}
