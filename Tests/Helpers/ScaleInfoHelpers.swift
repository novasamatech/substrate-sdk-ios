import Foundation
import FearlessUtils

enum ScaleInfoHelperError: Error {
    case invalidMetadataFilename
}

final class ScaleInfoHelper {
    static func createScaleInfoMetadata(for fileName: String) throws -> RuntimeMetadataV14 {
        guard let metadataUrl = Bundle(for: self).url(forResource: fileName, withExtension: "") else {
            throw ScaleInfoHelperError.invalidMetadataFilename
        }

        let hex = try String(contentsOf: metadataUrl)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let data = try Data(hexString: hex)

        let decoder = try ScaleDecoder(data: data)
        let container = try RuntimeMetadataContainer(scaleDecoder: decoder)

        switch container.runtimeMetadata {
        case .v14(let metadata):
            return metadata
        case .v13:
            throw RuntimeHelperError.unexpectedMetadata
        }
    }

    static func createTypeRegistry(
        from fileName: String,
        networkFilename: String = "common-v14"
    ) throws -> TypeRegistryCatalog {
        let runtimeMetadata = try Self.createScaleInfoMetadata(for: fileName)

        guard let networkUrl = Bundle(for: self).url(
                forResource: networkFilename,
                withExtension: "json"
        ) else {
            throw RuntimeHelperError.invalidCatalogNetworkName
        }

        let networdData = try Data(contentsOf: networkUrl)

        return try TypeRegistryCatalog.createFromSiDefinition(
            versioningData: networdData,
            runtimeMetadata: runtimeMetadata,
            customNameMapper: ScaleInfoCamelCaseMapper()
        )
    }
}
