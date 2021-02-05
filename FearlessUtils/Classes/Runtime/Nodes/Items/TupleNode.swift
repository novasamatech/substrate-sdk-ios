import Foundation

public struct TupleNode: Node {
    public let typeName: String
    public let innerNodes: [Node]

    public init(typeName: String, innerNodes: [Node]) {
        self.typeName = typeName
        self.innerNodes = innerNodes
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let components = value.arrayValue else {
            throw DynamicScaleEncoderError.unexpectedTupleJSON(json: value)
        }

        guard components.count == innerNodes.count else {
            throw DynamicScaleEncoderError.unexpectedTupleComponents(count: components.count,
                                                                     actual: innerNodes.count)
        }

        for index in 0..<innerNodes.count {
            try encoder.append(json: components[index], type: innerNodes[index].typeName)
        }
    }
}
