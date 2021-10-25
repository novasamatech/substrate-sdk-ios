import Foundation

public class BoxProposalNode: Node {
    public var typeName: String { GenericType.boxProposal.name }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.append(json: value, type: GenericType.call.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.read(type: GenericType.call.name)
    }
}
