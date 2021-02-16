import Foundation

public struct StructNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let mapping = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        guard typeMapping.count == mapping.count else {
            let fieldNames = typeMapping.map { $0.name }
            throw DynamicScaleEncoderError.unexpectedStructFields(json: value,
                                                                  expectedFields: fieldNames)
        }

        for index in 0..<typeMapping.count {
            guard let child = mapping[typeMapping[index].name] else {
                throw DynamicScaleCoderError.unresolverType(name: typeMapping[index].name)
            }

            try encoder.append(json: child, type: typeMapping[index].node.typeName)
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let dictJson = try typeMapping.reduce(into: [String: JSON]()) { (result, item) in
            let json = try decoder.read(type: item.node.typeName)
            result[item.name] = json
        }

        return .dictionaryValue(dictJson)
    }
}
