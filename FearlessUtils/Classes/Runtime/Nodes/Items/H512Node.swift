import Foundation

public struct H512Node: Node {
    public var typeName: String { GenericType.h512.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendBytes(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readBytes(length: 64)
    }
}
