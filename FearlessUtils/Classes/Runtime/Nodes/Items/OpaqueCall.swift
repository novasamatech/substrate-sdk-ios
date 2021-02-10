import Foundation

public struct OpaqueCallNode: Node {
    public var typeName: String { "OpaqueCall" }
    public let runtimeMetadata: RuntimeMetadata

    public init(runtimeMetadata: RuntimeMetadata) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.append(json: value, type: "Call")
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.read(type: "Call")
    }
}
