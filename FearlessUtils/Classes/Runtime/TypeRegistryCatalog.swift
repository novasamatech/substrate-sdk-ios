import Foundation

enum TypeRegistryCatalogError: Error {
    case missingVersioning
    case duplicatedVersioning
}

public protocol TypeRegistryCatalogProtocol {
    func node(for typeName: String, version: UInt64) -> Node?
}

/**
 *  Class is designed to provide an interface to access different versions of the type
 *  definition graphs.
 */

public class TypeRegistryCatalog: TypeRegistryCatalogProtocol {
    public let baseRegistry: TypeRegistry
    public let versionedRegistries: [UInt64: TypeRegistry]
    public let versionedTypes: [String: [UInt64]]
    public let typeResolver: TypeResolving

    public init(baseRegistry: TypeRegistry, versionedRegistries: [UInt64: TypeRegistry], typeResolver: TypeResolving) {
        self.baseRegistry = baseRegistry
        self.versionedRegistries = versionedRegistries
        self.typeResolver = typeResolver

        let allVersions = versionedRegistries.keys.sorted()

        versionedTypes = allVersions.reduce(into: [String: [UInt64]]()) { (result, item) in
            guard let typeRegistry = versionedRegistries[item] else {
                return
            }

            let typeNames = typeRegistry.registeredTypeNames.filter { !(typeRegistry.node(for: $0) is GenericNode) }

            for typeName in typeNames {
                let versions: [UInt64] = result[typeName] ?? []

                if versions.last != item {
                    result[typeName] = versions + [item]
                }
            }
        }
    }

    public func node(for typeName: String, version: UInt64) -> Node? {
        let registry = getRegistry(for: typeName, version: version)
        return registry.node(for: typeName)
    }

    // MARK: Private

    func getRegistry(for typeName: String, version: UInt64) -> TypeRegistry {

        let versions: [UInt64]

        if let typeVersions = versionedTypes[typeName] {
            versions = typeVersions
        } else if let resolvedName = typeResolver.resolve(typeName: typeName, using: Set(versionedTypes.keys)) {
            versions = versionedTypes[resolvedName] ?? []
        } else {
            versions = []
        }

        guard let minVersion = versions.reversed().first(where: { $0 <= version }) else {
            return baseRegistry
        }

        return versionedRegistries[minVersion] ?? baseRegistry
    }
}

public extension TypeRegistryCatalog {
    static func createFromBaseTypeDefinition(_ baseDefinitionData: Data,
                                             networkDefinitionData: Data,
                                             runtimeMetadata: RuntimeMetadata,
                                             version: UInt64)
    throws -> TypeRegistryCatalog {
        let versionedDefinitionJson = try JSONDecoder().decode(JSON.self, from: networkDefinitionData)

        guard let versioning = versionedDefinitionJson.versioning?.arrayValue else {
            throw TypeRegistryCatalogError.missingVersioning
        }

        let versionedJsons = versioning.reduce(into: [UInt64: JSON]()) { (result, versionedJson) in
            guard
                let version = versionedJson.runtime_range?.arrayValue?.first?.unsignedIntValue,
                let definitionDic = versionedJson.types?.dictValue else {
                return
            }

            let typeKey = "types"

            if let oldDefinitionDic = result[version]?.types?.dictValue {
                let mapping = oldDefinitionDic.merging(definitionDic) { (v1, v2) in v1 }
                result[version] = .dictionaryValue([typeKey: .dictionaryValue(mapping)])
            } else {
                result[version] = .dictionaryValue([typeKey: .dictionaryValue(definitionDic)])
            }
        }

        let baseRegistry = try TypeRegistry
            .createFromTypesDefinition(data: networkDefinitionData,
                                       runtimeMetadata: runtimeMetadata)
        let versionedRegistries = try versionedJsons.mapValues {
            try TypeRegistry.createFromTypesDefinition(json: $0, additionalNodes: [])
        }

        let typeResolver = OneOfTypeResolver(children: [
            CaseInsensitiveResolver()
        ])

        return TypeRegistryCatalog(baseRegistry: baseRegistry,
                                   versionedRegistries: versionedRegistries,
                                   typeResolver: typeResolver)
    }
}
