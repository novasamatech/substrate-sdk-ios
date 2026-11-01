import Foundation
import Testing
import SubstrateScaleCodable

@ScaleCodable(maxDepth: 32)
private indirect enum Tree: Equatable {
    case leaf
    case node([Tree])
}

@ScaleCodable(maxDepth: 2)
private struct Wrapper: Equatable {
    let tree: Tree
}

struct ScaleCodableDepthTests {
    private func nestedTree(nodes: Int) -> Data {
        Data(repeating: 0, count: 0)
            + Data((0 ..< nodes).flatMap { _ in [UInt8(0x01), 0x04] })
            + Data([0x00])
    }

    @Test func decodesNestingAtLimit() throws {
        // 31 nodes + leaf = 32 nested Tree decodes
        let tree = try Tree(scaleDecoder: ScaleDecoder(data: nestedTree(nodes: 31)))

        #expect(tree != .leaf)
    }

    @Test func throwsMaxDepthExceededWhenNestingExceedsLimit() {
        let expected = ScaleDecodingDepthError.maxDepthExceeded(typeName: String(describing: Tree.self), limit: 32)

        #expect(throws: expected) {
            try Tree(scaleDecoder: ScaleDecoder(data: nestedTree(nodes: 32)))
        }
    }

    @Test func throwsInsteadOfOverflowingStackOnHugePayload() {
        #expect(throws: ScaleDecodingDepthError.self) {
            try Tree(scaleDecoder: ScaleDecoder(data: nestedTree(nodes: 100_000)))
        }
    }

    @Test func restoresDepthAfterFailure() throws {
        _ = try? Tree(scaleDecoder: ScaleDecoder(data: nestedTree(nodes: 32)))

        #expect(try Tree(scaleDecoder: ScaleDecoder(data: nestedTree(nodes: 31))) != .leaf)
    }

    @Test func countsDepthPerType() throws {
        // Wrapper's own limit (2) doesn't constrain Tree's nesting
        let wrapper = try Wrapper(scaleDecoder: ScaleDecoder(data: nestedTree(nodes: 10)))

        #expect(wrapper.tree != .leaf)
    }
}
