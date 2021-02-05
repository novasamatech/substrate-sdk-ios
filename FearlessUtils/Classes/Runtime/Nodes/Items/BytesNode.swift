import Foundation

public struct BytesNode: Node {
    public var typeName: String { "Bytes" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendVector(json: value, type: "u8")
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readVector(type: "u8")
    }
}
