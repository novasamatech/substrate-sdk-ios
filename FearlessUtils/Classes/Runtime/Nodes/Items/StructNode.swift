import Foundation

public struct StructNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let fieldValues = value.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: value)
        }

        guard typeMapping.count == fieldValues.count else {
            let fieldNames = typeMapping.map { $0.name }
            throw DynamicScaleEncoderError.unexpectedStructFields(json: value,
                                                                  expectedFields: fieldNames)
        }

        for index in 0..<typeMapping.count {
            try encoder.append(json: fieldValues[index], type: typeMapping[index].node.typeName)
        }
    }
}
