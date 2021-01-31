import Foundation

enum NumericSetNodeFactoryError: Error {
    case invalidBitMapping
}

class NumericSetNodeFactory: TypeNodeFactoryProtocol {
    let parser: TypeParser

    init(parser: TypeParser) {
        self.parser = parser
    }

    func buildNode(from json: JSON, typeName: String, mediator: TypeRegistering) throws -> Node? {
        guard let items = parser.parse(json: json) else {
            return nil
        }

        guard let itemType = items.first, let itemTypeName = itemType.stringValue else {
            return nil
        }

        let itemTypeNode = mediator.register(typeName: itemTypeName, json: itemType)

        let bitVector: [SetNode.Item] = try items.dropFirst().map { bitItem in
            guard
                let components = bitItem.arrayValue,
                components.count == 2,
                let name = components.first?.stringValue,
                let value = components.last?.unsignedIntValue else {
                throw NumericSetNodeFactoryError.invalidBitMapping
            }

            return SetNode.Item(name: name, value: value)
        }

        return SetNode(typeName: typeName, bitVector: bitVector, itemType: itemTypeNode)
    }
}
