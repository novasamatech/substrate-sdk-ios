import Foundation

public protocol Node: AnyObject, DynamicScaleCodable {
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

public struct IndexedNameNode {
    public let index: UInt8
    public let name: String
    public let node: Node

    init(index: UInt8, name: String, node: Node) {
        self.index = index
        self.name = name
        self.node = node
    }
}
