import Foundation

public enum TypeRegistryError: Error {
    case unexpectedJson
    case invalidKey(String)
}

protocol TypeRegistering {
    func register(typeName: String, json: JSON) -> Node
}

public class TypeRegistry {
    private var graph: [String: Node] = [:]
    private var nodeFactory: TypeNodeFactoryProtocol

    public var registeredTypes: [Node] { graph.keys.compactMap { graph[$0] } }

    init(json: JSON, nodeFactory: TypeNodeFactoryProtocol) throws {
        self.nodeFactory = nodeFactory

        try parse(json: json)
    }

    // MARK: Private

    private func parse(json: JSON) throws {
        guard let dict = json.dictValue else {
            throw TypeRegistryError.unexpectedJson
        }

        let keyParser = TermParser.generic()

        let refinedDict = try dict.reduce(into: [String: JSON]()) { (result, item) in
            if let type = keyParser.parse(json: .stringValue(item.key))?.first?.stringValue {
                result[type] = item.value
            } else {
                throw TypeRegistryError.invalidKey(item.key)
            }
        }

        for typeName in refinedDict.keys {
            graph[typeName] = GenericNode(typeName: typeName)
        }

        for item in refinedDict {
            if let node = try nodeFactory.buildNode(from: item.value,
                                                    typeName: item.key,
                                                    mediator: self) {
                graph[item.key] = node
            }
        }
    }
}

public extension TypeRegistry {
    static func createFromTypesDefinition(data: Data) throws -> TypeRegistry {
        let jsonDecoder = JSONDecoder()
        let json = try jsonDecoder.decode(JSON.self, from: data)

        guard let types = json.types else {
            throw TypeRegistryError.unexpectedJson
        }

        let factories: [TypeNodeFactoryProtocol] = [
            StructNodeFactory(parser: TypeMappingParser.structure()),
            EnumNodeFactory(parser: TypeMappingParser.enumeration()),
            EnumValuesNodeFactory(parser: TypeValuesParser.enumeration()),
            NumericSetNodeFactory(parser: TypeSetParser.generic())
        ]

        return try TypeRegistry(json: types,
                                nodeFactory: OneOfTypeNodeFactory(children: factories))
    }
}

extension TypeRegistry: TypeRegistering {
    func register(typeName: String, json: JSON) -> Node {
        let proxy = ProxyNode(typeName: typeName, resolver: self)

        guard graph[typeName] == nil else {
            return proxy
        }

        graph[typeName] = GenericNode(typeName: typeName)

        if let node = try? nodeFactory.buildNode(from: json, typeName: typeName, mediator: self) {
            graph[typeName] = node
        }

        return proxy
    }
}

extension TypeRegistry: NodeResolver {
    public func resolve(for key: String) -> Node? { graph[key] }
}
