import Foundation

public struct FixedArrayNode: Node {
    public let typeName: String
    public let elementType: Node
    public let length: UInt64

    public init(typeName: String, elementType: Node, length: UInt64) {
        self.typeName = typeName
        self.elementType = elementType
        self.length = length
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendFixedArray(json: value, type: elementType.typeName)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readFixedArray(type: elementType.typeName, length: length)
    }
}
