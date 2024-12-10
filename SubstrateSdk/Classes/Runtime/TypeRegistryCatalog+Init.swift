import Foundation

public extension TypeRegistryCatalog {
    static func createFromTypeDefinition(_ definitionData: Data,
                                         versioningData: Data,
                                         runtimeMetadata: RuntimeMetadata,
                                         customNodes: [Node] = [],
                                         customExtensions: [TransactionExtensionCoding] = [])
    throws -> TypeRegistryCatalog {
        let versionedJsons = try prepareVersionedJsons(from: versioningData)

        return try createFromTypeDefinition(
            definitionData,
            versionedJsons: versionedJsons,
            runtimeMetadata: runtimeMetadata,
            customNodes: customNodes,
            customExtensions: customExtensions
        )
    }

    static func createFromTypeDefinition(
        _ definitionData: Data,
        runtimeMetadata: RuntimeMetadata,
        customNodes: [Node] = [],
        customExtensions: [TransactionExtensionCoding] = []
    ) throws -> TypeRegistryCatalog {
        try createFromTypeDefinition(
            definitionData,
            versionedJsons: [:],
            runtimeMetadata: runtimeMetadata,
            customNodes: customNodes,
            customExtensions: customExtensions
        )
    }

    static func createFromTypeDefinition(_ definitionData: Data,
                                         versionedJsons: [UInt64: JSON],
                                         runtimeMetadata: RuntimeMetadata,
                                         customNodes: [Node],
                                         customExtensions: [TransactionExtensionCoding])
    throws -> TypeRegistryCatalog {
        let allNodes = BasisNodes.allNodes(for: runtimeMetadata, customExtensions: customExtensions)
        let additonalNodes = allNodes + customNodes
        let baseRegistry = try TypeRegistry
            .createFromTypesDefinition(data: definitionData,
                                       additionalNodes: additonalNodes)

        let versionedRegistries = try versionedJsons.mapValues {
            try TypeRegistry.createFromTypesDefinition(json: $0, additionalNodes: [])
        }

        let typeResolver = OneOfTypeResolver(children: [
            CaseInsensitiveResolver(),
            TableResolver.noise(),
            RegexReplaceResolver.noise(),
            RegexReplaceResolver.genericsFilter()
        ])

        let runtimeMetadataRegistry = try TypeRegistry
            .createFromRuntimeMetadata(runtimeMetadata,
                                       additionalTypes: RuntimeTypes.known)

        return TypeRegistryCatalog(baseRegistry: baseRegistry,
                                   versionedRegistries: versionedRegistries,
                                   runtimeMetadataRegistry: runtimeMetadataRegistry,
                                   typeResolver: typeResolver)
    }

    static func createFromSiDefinition(
        versioningData: Data,
        runtimeMetadata: PostV14RuntimeMetadataProtocol,
        additionalNodes: [Node] = [],
        customExtensions: [TransactionExtensionCoding] = [],
        customTypeMapper: SiTypeMapping? = nil,
        customNameMapper: SiNameMapping? = nil
    ) throws -> TypeRegistryCatalog {
        let versionedJsons = try prepareVersionedJsons(from: versioningData)

        return try createFromSiDefinition(
            runtimeMetadata: runtimeMetadata,
            versionedJsons: versionedJsons,
            additionalNodes: additionalNodes,
            customExtensions: customExtensions,
            customTypeMapper: customTypeMapper,
            customNameMapper: customNameMapper
        )
    }

    static func createFromSiDefinition(
        runtimeMetadata: PostV14RuntimeMetadataProtocol,
        versionedJsons: [UInt64: JSON] = [:],
        additionalNodes: [Node] = [],
        customExtensions: [TransactionExtensionCoding] = [],
        customTypeMapper: SiTypeMapping? = nil,
        customNameMapper: SiNameMapping? = nil
    ) throws -> TypeRegistryCatalog {
        let runtimeRegistry: SiTypeRegistry = SiTypeRegistry.createFromTypesLookup(
            runtimeMetadata,
            additionalNodes: additionalNodes,
            customExtensions: customExtensions,
            customTypeMapper: customTypeMapper,
            customNameMapper: customNameMapper
        )

        let versionedRegistries = try versionedJsons.mapValues {
            try TypeRegistry.createFromTypesDefinition(json: $0, additionalNodes: [])
        }

        return TypeRegistryCatalog(
            baseRegistry: runtimeRegistry,
            versionedRegistries: versionedRegistries,
            runtimeMetadataRegistry: nil,
            typeResolver: nil
        )
    }

    private static func prepareVersionedJsons(from data: Data) throws -> [UInt64: JSON] {
        let versionedDefinitionJson = try JSONDecoder().decode(JSON.self, from: data)

        guard let versioning = versionedDefinitionJson.versioning?.arrayValue else {
            throw TypeRegistryCatalogError.missingVersioning
        }

        guard let currentVersion = versionedDefinitionJson.runtime_id?.unsignedIntValue else {
            throw TypeRegistryCatalogError.missingCurrentVersion
        }

        guard let types = versionedDefinitionJson.types else {
            throw TypeRegistryCatalogError.missingNetworkTypes
        }

        let typeKey = "types"

        let initDict = [currentVersion: JSON.dictionaryValue([typeKey: types])]

        return versioning.reduce(into: initDict) { (result, versionedJson) in
            guard
                let version = versionedJson.runtime_range?.arrayValue?.first?.unsignedIntValue,
                let definitionDic = versionedJson.types?.dictValue else {
                return
            }

            if let oldDefinitionDic = result[version]?.types?.dictValue {
                let mapping = oldDefinitionDic.merging(definitionDic) { (v1, _) in v1 }
                result[version] = .dictionaryValue([typeKey: .dictionaryValue(mapping)])
            } else {
                result[version] = .dictionaryValue([typeKey: .dictionaryValue(definitionDic)])
            }
        }
    }
}
