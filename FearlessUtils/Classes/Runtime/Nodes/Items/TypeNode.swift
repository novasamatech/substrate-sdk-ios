import Foundation

public protocol Node: DynamicScaleCodable {
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
