import Foundation

public protocol Node {
    var typeName: String { get }
}

public struct StructNode: Node {
    public let typeName: String
    let typeMapping: [Node]
}

public struct EnumNode: Node {
    public let typeName: String
    let cases: [Node]
}

public struct SetNode: Node {
    public let typeName: String
    let bitVector: Node
}

public struct OptionNode: Node {
    public let typeName: String
    let underlying: Node
}

public struct CompactNode: Node {
    public let typeName: String
}

public struct VectorNode: Node {
    public let typeName: String
    let underlying: Node
}

public struct TupleNode: Node {
    public let typeName: String
    let innerNodes: [Node]
}

public protocol NodeResolver: class {
    func resolve(for key: String) -> Node
}

public struct ProxyNode: Node {
    public let typeName: String
    public weak var resolver: NodeResolver?

    public init(typeName: String, resolver: NodeResolver) {
        self.typeName = typeName
        self.resolver = resolver
    }
}
