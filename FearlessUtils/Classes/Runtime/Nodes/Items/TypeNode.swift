import Foundation

public protocol Node: DynamicScaleCodable {
    var typeName: String { get }
}

public extension Node {
    func accept(encoder: DynamicScaleEncoding, value: JSON) throws {}
    func accept(decoder: DynamicScaleDecoding) throws -> JSON { .null }
}

public struct NameNode {
    public let name: String
    public let node: Node

    init(name: String, node: Node) {
        self.name = name
        self.node = node
    }
}
