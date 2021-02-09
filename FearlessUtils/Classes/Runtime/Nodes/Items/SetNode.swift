import Foundation

public struct SetNode: Node {
    public struct Item: Hashable, Equatable {
        public let name: String
        public let value: UInt64

        public init(name: String, value: UInt64) {
            self.name = name
            self.value = value
        }
    }

    public let typeName: String
    public let bitVector: Set<Item>
    public let itemType: Node

    init(typeName: String, bitVector: Set<Item>, itemType: Node) {
        self.typeName = typeName
        self.bitVector = bitVector
        self.itemType = itemType
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.append(json: value, type: itemType.typeName)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.read(type: itemType.typeName)
    }
}
