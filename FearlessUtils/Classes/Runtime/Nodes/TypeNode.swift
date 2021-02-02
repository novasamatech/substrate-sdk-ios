import Foundation

public protocol Node {
    var typeName: String { get }
}

public struct NameNode {
    public let name: String
    public let node: Node

    init(name: String, node: Node) {
        self.name = name
        self.node = node
    }
}

public struct GenericNode: Node {
    public let typeName: String
}

public struct StructNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }
}

public struct EnumNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }
}

public struct EnumValuesNode: Node {
    public let typeName: String
    public let values: [String]

    public init(typeName: String, values: [String]) {
        self.typeName = typeName
        self.values = values
    }
}

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
}

public struct OptionNode: Node {
    public let typeName: String
    public let underlying: Node

    public init(typeName: String, underlying: Node) {
        self.typeName = typeName
        self.underlying = underlying
    }
}

public struct CompactNode: Node {
    public let typeName: String
    public let underlying: Node

    public init(typeName: String, underlying: Node) {
        self.typeName = typeName
        self.underlying = underlying
    }
}

public struct VectorNode: Node {
    public let typeName: String
    public let underlying: Node

    public init(typeName: String, underlying: Node) {
        self.typeName = typeName
        self.underlying = underlying
    }
}

public struct TupleNode: Node {
    public let typeName: String
    public let innerNodes: [Node]

    public init(typeName: String, innerNodes: [Node]) {
        self.typeName = typeName
        self.innerNodes = innerNodes
    }
}

public struct FixedArrayNode: Node {
    public let typeName: String
    public let elementType: Node
    public let length: UInt64

    public init(typeName: String, elementType: Node, length: UInt64) {
        self.typeName = typeName
        self.elementType = elementType
        self.length = length
    }
}

public protocol NodeResolver: class {
    func resolve(for key: String) -> Node?
}

public struct ProxyNode: Node {
    public let typeName: String
    public weak var resolver: NodeResolver?

    public init(typeName: String, resolver: NodeResolver) {
        self.typeName = typeName
        self.resolver = resolver
    }
}
