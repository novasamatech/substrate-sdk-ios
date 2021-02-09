import Foundation

public struct H256Node: Node {
    public var typeName: String { "H256" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendBytes(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readBytes(length: 32)
    }
}
