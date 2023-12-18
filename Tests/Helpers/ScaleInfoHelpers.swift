import Foundation
import SubstrateSdk

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
        networkFilename: String = "common-v14",
        customExtensions: [ExtrinsicExtensionCoder] = []
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
            customExtensions: customExtensions,
            customNameMapper: ScaleInfoCamelCaseMapper()
        )
    }
    
    static func createTypeRegistryWithoutVersioning(
        from fileName: String,
        customExtensions: [ExtrinsicExtensionCoder] = []
    ) throws -> TypeRegistryCatalog {
        let runtimeMetadata = try Self.createScaleInfoMetadata(for: fileName)
        
        let predefinedNodes = RuntimeAugmentationFactory().createSubstrateAugmentation(for: runtimeMetadata)

        return try TypeRegistryCatalog.createFromSiDefinition(
            runtimeMetadata: runtimeMetadata,
            additionalNodes: predefinedNodes.additionalNodes.nodes,
            customExtensions: customExtensions,
            customNameMapper: ScaleInfoCamelCaseMapper()
        )
    }
}
