import Foundation

public class OpaqueCallNode: Node {
    public var typeName: String { GenericType.opaqueCall.name }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.append(json: value, type: KnownType.call.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.read(type: KnownType.call.name)
    }
}
