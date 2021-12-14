import Foundation

public class GenericAccountIdNode: Node {
    public var typeName: String { GenericType.accountId.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        if value.stringValue != nil {
            // process hex representation
            try encoder.appendBytes(json: value)
        } else {
            // process byte array representation
            try encoder.appendFixedArray(json: value, type: PrimitiveType.u8.rawValue)
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readBytes(length: 32)
    }
}
