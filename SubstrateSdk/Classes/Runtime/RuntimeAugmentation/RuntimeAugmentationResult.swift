import Foundation

public struct RuntimeAugmentationResult {
    public struct AdditionalNodes {
        public let nodes: [Node]
        public let notMatch: Set<String>

        public init(nodes: [Node], notMatch: Set<String>) {
            self.nodes = nodes
            self.notMatch = notMatch
        }

        public func adding(node: Node) -> AdditionalNodes {
            .init(nodes: nodes + [node], notMatch: notMatch)
        }

        public func adding(notMatchedType: String) -> AdditionalNodes {
            .init(nodes: nodes, notMatch: notMatch.union([notMatchedType]))
        }
    }

    public let additionalNodes: AdditionalNodes
}
