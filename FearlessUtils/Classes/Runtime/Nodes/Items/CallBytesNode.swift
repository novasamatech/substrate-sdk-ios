import Foundation

public struct CallBytesNode: Node {
    public var typeName: String { "CallBytes" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendBytes(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        throw DynamicScaleCoderError.notImplemented
    }
}
