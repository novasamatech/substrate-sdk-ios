import Foundation

public extension TypeRegistryCatalog {
    static func createFromBaseTypeDefinition(_ baseDefinitionData: Data,
                                             networkDefinitionData: Data,
                                             runtimeMetadata: RuntimeMetadata,
                                             customNodes: [Node] = [])
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
                let mapping = oldDefinitionDic.merging(definitionDic) { (v1, _) in v1 }
                result[version] = .dictionaryValue([typeKey: .dictionaryValue(mapping)])
            } else {
                result[version] = .dictionaryValue([typeKey: .dictionaryValue(definitionDic)])
            }
        }

        let additonalNodes = BasisNodes.allNodes(for: runtimeMetadata) + customNodes
        let baseRegistry = try TypeRegistry
            .createFromTypesDefinition(data: baseDefinitionData,
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
}
