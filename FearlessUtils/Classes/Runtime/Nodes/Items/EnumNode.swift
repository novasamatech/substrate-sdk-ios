import Foundation

public struct EnumNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard
            let enumValue = value.arrayValue,
            enumValue.count == 2,
            let caseValue = enumValue.first?.unsignedIntValue,
            let assocValue = enumValue.last else {
            throw DynamicScaleEncoderError.unexpectedEnumJSON(json: value)
        }

        guard caseValue < typeMapping.count else {
            throw DynamicScaleEncoderError.unexpectedEnumCase(value: caseValue, count: typeMapping.count)
        }

        try encoder.appendU8(json: .stringValue(String(caseValue)))
        try encoder.append(json: assocValue, type: typeMapping[Int(caseValue)].node.typeName)
    }
}
