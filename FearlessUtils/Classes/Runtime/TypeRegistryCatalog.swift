import Foundation

enum TypeRegistryCatalogError: Error {
    case missingVersioning
    case missingCurrentVersion
    case missingNetworkTypes
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
    public let runtimeMetadataRegistry: TypeRegistryProtocol?
    public let baseRegistry: TypeRegistryProtocol
    public let versionedRegistries: [UInt64: TypeRegistryProtocol]
    public let versionedTypes: [String: [UInt64]]
    public let typeResolver: TypeResolving?

    public let allTypes: Set<String>
    public let mutex = NSLock()
    public var registryCache: [String: TypeRegistryProtocol] = [:]

    public init(baseRegistry: TypeRegistryProtocol,
                versionedRegistries: [UInt64: TypeRegistryProtocol],
                runtimeMetadataRegistry: TypeRegistryProtocol?,
                typeResolver: TypeResolving?) {
        self.baseRegistry = baseRegistry
        self.versionedRegistries = versionedRegistries
        self.runtimeMetadataRegistry = runtimeMetadataRegistry
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

        allTypes = Set(versionedTypes.keys)
    }

    public func node(for typeName: String, version: UInt64) -> Node? {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let cacheKey = "\(typeName)_\(version)"

        if let registry = registryCache[cacheKey] {
            return registry.node(for: typeName)
        }

        let registry = getRegistry(for: typeName, version: version)
        return fallbackToRuntimeMetadataIfNeeded(from: registry, typeName: typeName, cacheKey: cacheKey)
    }

    public func replacingRuntimeMetadata(_ newMetadata: RuntimeMetadata) throws
    -> TypeRegistryCatalogProtocol {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        registryCache = [:]

        let newRuntimeRegistry = try TypeRegistry.createFromRuntimeMetadata(newMetadata)

        return TypeRegistryCatalog(baseRegistry: baseRegistry,
                                   versionedRegistries: versionedRegistries,
                                   runtimeMetadataRegistry: newRuntimeRegistry,
                                   typeResolver: typeResolver)
    }

    // MARK: Private

    private func getRegistry(for typeName: String, version: UInt64) -> TypeRegistryProtocol {

        let versions: [UInt64]

        if let typeVersions = versionedTypes[typeName] {
            versions = typeVersions
        } else if let resolvedName = typeResolver?.resolve(typeName: typeName, using: allTypes) {
            versions = versionedTypes[resolvedName] ?? []
        } else {
            versions = []
        }

        guard let minVersion = versions.reversed().first(where: { $0 <= version }) else {
            return baseRegistry
        }

        return versionedRegistries[minVersion] ?? baseRegistry
    }

    private func fallbackToRuntimeMetadataIfNeeded(from registry: TypeRegistryProtocol,
                                                   typeName: String,
                                                   cacheKey: String) -> Node? {
        if let node = registry.node(for: typeName) {
            registryCache[cacheKey] = registry
            return node
        }

        registryCache[cacheKey] = runtimeMetadataRegistry
        return runtimeMetadataRegistry?.node(for: typeName)
    }
}
