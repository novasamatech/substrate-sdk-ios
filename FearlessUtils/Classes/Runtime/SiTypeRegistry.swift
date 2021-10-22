import Foundation

protocol ScaleInfoRegistring {
    func register(identifier: String) -> Node
}

public class SiTypeRegistry: TypeRegistryProtocol {
    private var allKeys: Set<String>
    private let types: [String: RuntimeType]
    private let nodeFactory: ScaleInfoNodeFactoryProtocol
    private let baseNodes: [String: Node]

    public var registeredTypes: [Node] { [] }
    public var registeredTypeNames: Set<String> { allKeys }

    public func node(for key: String) -> Node? {
        if let node = baseNodes[key] {
            return node
        }

        if let type = types[key] {
            return nodeFactory.buildNode(from: type, identifier: key)
        }

        return nil
    }

    init(typesLookup: RuntimeTypesLookup, baseNodes: [Node], nodeFactory: ScaleInfoNodeFactoryProtocol) {
        types = typesLookup.types.reduce(into: [:]) { (result, item) in
            let key = String(item.identifier)
            result[key] = item.type
         }

        let baseKeys = Set(baseNodes.map({ $0.typeName }))

        allKeys = Set(types.keys).union(baseKeys)

        self.nodeFactory = nodeFactory
        self.baseNodes = baseNodes.reduce(into: [:]) { (result, item) in
            result[item.typeName] = item
        }
    }
}

public extension SiTypeRegistry {
    static func createFromTypesLookup(
        _ metadata: RuntimeMetadataV14,
        additionalNodes: [Node] = [],
        customTypeMapper: SiTypeMapping? = nil,
        customNameMapper: SiNameMapping? = nil
    ) -> SiTypeRegistry {
        var genericTypeMappings = createGenericTypeMappers()

        if let customTypeMapper = customTypeMapper {
            genericTypeMappings.append(customTypeMapper)
        }

        let typeMapping = OneOfSiTypeMapper(innerMappers: genericTypeMappings)

        let nodeFactory = ScaleInfoNodeFactory(typeMapper: typeMapping, nameMapper: customNameMapper)

        let baseNodes = BasisNodes.allNodes(for: metadata) + additionalNodes
        let registry = SiTypeRegistry(
            typesLookup: metadata.types,
            baseNodes: baseNodes,
            nodeFactory: nodeFactory
        )

        return registry
    }
}

extension SiTypeRegistry {
    static func createGenericTypeMappers() -> [SiTypeMapping] {
        [
            SiOptionTypeMapper(),
            SiSetTypeMapper(),
            SiClosureTypeMapper { $0.path.last == "AccountId32" ? GenericAccountIdNode() : nil },
            SiCompositeNoneToAliasMapper()
        ]
    }
}
