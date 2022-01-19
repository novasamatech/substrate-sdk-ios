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

        guard let type = types[key] else {
            return nil
        }

        let maybePathBasedName = type.pathBasedName

        if let pathBasedName = maybePathBasedName, let node = baseNodes[pathBasedName] {
            return node
        } else if let pathBasedName = maybePathBasedName, key != pathBasedName, types[pathBasedName] != nil {
            return AliasNode(typeName: key, underlyingTypeName: pathBasedName)
        } else {
            return nodeFactory.buildNode(from: type, identifier: key)
        }
    }

    init(typesLookup: RuntimeTypesLookup, baseNodes: [Node], nodeFactory: ScaleInfoNodeFactoryProtocol) {
        let pathDuplications: [String: Int] = typesLookup.types.reduce(into: [:]) { (result, item) in
            guard let pathBasedName = item.type.pathBasedName else {
                return
            }

            if let counter = result[pathBasedName] {
                result[pathBasedName] = counter + 1
            } else {
                result[pathBasedName] = 1
            }
        }

        types = typesLookup.types.reduce(into: [:]) { (result, item) in
            let key = String(item.identifier)
            result[key] = item.type

            guard let pathBasedName = item.type.pathBasedName else {
                return
            }

            let counter = pathDuplications[pathBasedName] ?? 0

            guard counter <= 1 else {
                return
            }

            result[pathBasedName] = item.type
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
        customExtensions: [ExtrinsicExtensionCoder] = [],
        customTypeMapper: SiTypeMapping? = nil,
        customNameMapper: SiNameMapping? = nil
    ) -> SiTypeRegistry {
        var genericTypeMappings = createGenericTypeMappers()

        if let customTypeMapper = customTypeMapper {
            genericTypeMappings.append(customTypeMapper)
        }

        let typeMapping = OneOfSiTypeMapper(innerMappers: genericTypeMappings)

        let nodeFactory = ScaleInfoNodeFactory(typeMapper: typeMapping, nameMapper: customNameMapper)

        let allNodes = BasisNodes.allNodes(for: metadata, customExtensions: customExtensions)
        let baseNodes = allNodes + additionalNodes
        let registry = SiTypeRegistry(typesLookup: metadata.types, baseNodes: baseNodes, nodeFactory: nodeFactory)

        return registry
    }
}

extension SiTypeRegistry {
    static func createGenericTypeMappers() -> [SiTypeMapping] {
        [
            SiOptionTypeMapper(),
            SiSetTypeMapper(),
            SiCompositeNoneToAliasMapper()
        ]
    }
}
