import Foundation
import FearlessUtils

enum RuntimeHelperError: Error {
    case invalidCatalogBaseName
    case invalidCatalogNetworkName
    case invalidCatalogMetadataName
}

final class RuntimeHelper {
    static func createRuntimeMetadata(_ name: String) throws -> RuntimeMetadata {
        guard let metadataUrl = Bundle(for: self).url(forResource: name,
                                                      withExtension: "") else {
            throw RuntimeHelperError.invalidCatalogMetadataName
        }

        let hex = try String(contentsOf: metadataUrl)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let expectedData = try Data(hexString: hex)

        let decoder = try ScaleDecoder(data: expectedData)
        return try RuntimeMetadata(scaleDecoder: decoder)
    }

    static func createTypeRegistryCatalog(from baseName: String,
                                          networkName: String,
                                          runtimeMetadataName: String)
    throws -> TypeRegistryCatalogProtocol {
        guard let baseUrl = Bundle(for: self).url(forResource: baseName, withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogBaseName
        }

        guard let networkUrl = Bundle(for: self).url(forResource: networkName,
                                                     withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogNetworkName
        }

        let baseData = try Data(contentsOf: baseUrl)
        let networdData = try Data(contentsOf: networkUrl)

        let runtimeMetadata = try Self.createRuntimeMetadata(runtimeMetadataName)

        let registry = try TypeRegistryCatalog
            .createFromBaseTypeDefinition(baseData,
                                          networkDefinitionData: networdData,
                                          runtimeMetadata: runtimeMetadata,
                                          version: 45)

        return registry
    }
}
