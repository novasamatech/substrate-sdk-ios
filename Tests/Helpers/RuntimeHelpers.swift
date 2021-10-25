import Foundation
import SubstrateSdk

enum RuntimeHelperError: Error {
    case invalidCatalogBaseName
    case invalidCatalogNetworkName
    case invalidCatalogMetadataName
    case unexpectedMetadata
}

final class RuntimeHelper {
    static func createRuntimeMetadata(_ name: String) throws -> RuntimeMetadata {
        guard let metadataUrl = Bundle(for: self).url(forResource: name,
                                                      withExtension: "") else {
            throw RuntimeHelperError.invalidCatalogMetadataName
        }

        let hex = try String(contentsOf: metadataUrl)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let data = try Data(hexString: hex)

        let decoder = try ScaleDecoder(data: data)
        let container = try RuntimeMetadataContainer(scaleDecoder: decoder)

        switch container.runtimeMetadata {
        case .v13(let metadata):
            return metadata
        case .v14:
            throw RuntimeHelperError.unexpectedMetadata
        }
    }

    static func createTypeRegistry(from name: String, runtimeMetadataName: String) throws
    -> TypeRegistry {
        guard let url = Bundle(for: self).url(forResource: name, withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogBaseName
        }

        let runtimeMetadata = try Self.createRuntimeMetadata(runtimeMetadataName)

        let data = try Data(contentsOf: url)
        let basisNodes = BasisNodes.allNodes(for: runtimeMetadata)
        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data,
                                       additionalNodes: basisNodes)

        return registry
    }

    static func createTypeRegistryCatalog(from baseName: String,
                                          networkName: String,
                                          runtimeMetadataName: String)
    throws -> TypeRegistryCatalog {
        let runtimeMetadata = try Self.createRuntimeMetadata(runtimeMetadataName)

        return try createTypeRegistryCatalog(from: baseName,
                                             networkName: networkName,
                                             runtimeMetadata: runtimeMetadata)
    }

    static func createTypeRegistryCatalog(
        from baseName: String,
        runtimeMetadataName: String
    ) throws -> TypeRegistryCatalog {
        let runtimeMetadata = try Self.createRuntimeMetadata(runtimeMetadataName)

        return try createTypeRegistryCatalog(from: baseName, runtimeMetadata: runtimeMetadata)
    }

    static func createTypeRegistryCatalog(from baseName: String,
                                          networkName: String,
                                          runtimeMetadata: RuntimeMetadata)
    throws -> TypeRegistryCatalog {
        guard let baseUrl = Bundle(for: self).url(forResource: baseName, withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogBaseName
        }

        guard let networkUrl = Bundle(for: self).url(forResource: networkName,
                                                     withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogNetworkName
        }

        let baseData = try Data(contentsOf: baseUrl)
        let networdData = try Data(contentsOf: networkUrl)

        let registry = try TypeRegistryCatalog.createFromTypeDefinition(
            baseData,
            versioningData: networdData,
            runtimeMetadata: runtimeMetadata
        )

        return registry
    }

    static func createTypeRegistryCatalog(
        from baseName: String,
        runtimeMetadata: RuntimeMetadata
    ) throws -> TypeRegistryCatalog {
        guard let baseUrl = Bundle(for: self).url(forResource: baseName, withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogBaseName
        }

        let typesData = try Data(contentsOf: baseUrl)

        let registry = try TypeRegistryCatalog.createFromTypeDefinition(
            typesData,
            runtimeMetadata: runtimeMetadata
        )

        return registry
    }

    static let dummyRuntimeMetadata: RuntimeMetadata = {
        RuntimeMetadata(modules: [
                            ModuleMetadata(name: "A",
                                           storage: StorageMetadata(prefix: "_A", entries: []),
                                           calls: [
                                            CallMetadata(name: "B",
                                                             arguments: [
                                                                CallArgumentMetadata(name: "arg1", type: "bool"),
                                                                CallArgumentMetadata(name: "arg2", type: "u8")
                                                             ], documentation: [])
                                           ],
                                           events: [
                                            EventMetadata(name: "A",
                                                          arguments: ["bool", "u8"],
                                                          documentation: [])
                                           ],
                                           constants: [],
                                           errors: [],
                                           index: 1)
                        ],
                        extrinsic: ExtrinsicMetadata(version: 1,
                                                     signedExtensions: []))
    }()
}
