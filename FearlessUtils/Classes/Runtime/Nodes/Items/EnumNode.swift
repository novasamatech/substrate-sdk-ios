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

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let caseValueStr = try decoder.readU8().stringValue,
              let caseValue = Int(caseValueStr) else {
            throw DynamicScaleDecoderError.unexpectedEnumCase
        }

        guard caseValue < typeMapping.count else {
            throw DynamicScaleDecoderError.invalidEnumCase(value: caseValue, count: typeMapping.count)
        }

        let json = try decoder.read(type: typeMapping[caseValue].node.typeName)

        return .arrayValue([.unsignedIntValue(UInt64(caseValue)), json])
    }
}
