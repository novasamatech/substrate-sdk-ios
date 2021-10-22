import Foundation

public class SiVariantNode: Node {
    public let typeName: String
    public let typeMapping: [IndexedNameNode]

    public init(typeName: String, typeMapping: [IndexedNameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard
            let enumValue = value.arrayValue,
            enumValue.count == 2,
            let caseValue = enumValue.first?.stringValue,
            let assocValue = enumValue.last else {
            throw DynamicScaleEncoderError.unexpectedEnumJSON(json: value)
        }

        guard let mappingItem = typeMapping.first(where: { $0.name == caseValue }) else {
            throw DynamicScaleEncoderError.unexpectedEnumCase(value: caseValue)
        }

        try encoder.append(encodable: mappingItem.index)
        try mappingItem.node.accept(encoder: encoder, value: assocValue)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let caseValueStr = try decoder.readU8().stringValue,
              let caseValue = UInt8(caseValueStr) else {
            throw DynamicScaleDecoderError.unexpectedEnumCase
        }

        guard let mappingItem = typeMapping.first(where: { $0.index == caseValue }) else {
            throw DynamicScaleDecoderError.invalidEnumCase(value: Int(caseValue), count: typeMapping.count)
        }

        let json = try mappingItem.node.accept(decoder: decoder)

        return .arrayValue([.stringValue(mappingItem.name), json])
    }
}
