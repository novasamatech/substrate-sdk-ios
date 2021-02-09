import Foundation
import FearlessUtils

enum RuntimeHelperError: Error {
    case invalidCatalogBaseName
}

final class RuntimeHelper {
    static func createTypeRegistryCatalog(from baseName: String, networkName: String) throws -> TypeRegistryCatalogProtocol {
        guard let baseUrl = Bundle(for: self).url(forResource: baseName, withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogBaseName
        }

        guard let networkUrl = Bundle(for: self).url(forResource: networkName, withExtension: "json") else {
            throw RuntimeHelperError.invalidCatalogBaseName
        }

        let baseData = try Data(contentsOf: baseUrl)
        let networdData = try Data(contentsOf: networkUrl)

        return try TypeRegistryCatalog.createFromBaseTypeDefinition(baseData,
                                                                    networkDefinitionData: networdData)
    }
}
