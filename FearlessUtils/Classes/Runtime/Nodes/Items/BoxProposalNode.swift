import Foundation

public struct BoxProposalNode: Node {
    public var typeName: String { "BoxProposal" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {

    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        .null
    }
}
