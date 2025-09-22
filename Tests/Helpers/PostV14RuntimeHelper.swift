import Foundation
import SubstrateSdk

enum PostV14RuntimeHelperError: Error {
    case invalidMetadataFilename
}

public final class PostV14RuntimeHelper {
    public static func createMetadata(for fileName: String, isOpaque: Bool = false) throws -> PostV14RuntimeMetadataProtocol {
        let bundle: Bundle
#if SWIFT_PACKAGE
        bundle = Bundle.module
#else
        bundle = Bundle(for: self)
#endif
        guard let metadataUrl = bundle.url(forResource: fileName, withExtension: "") else {
            throw PostV14RuntimeHelperError.invalidMetadataFilename
        }

        let hex = try String(contentsOf: metadataUrl)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let data = try Data(hexString: hex)

        let container: RuntimeMetadataContainer
        
        if isOpaque {
            container = try RuntimeMetadataContainer.createFromOpaque(data: data)
        } else {
            let decoder = try ScaleDecoder(data: data)
            container = try RuntimeMetadataContainer(scaleDecoder: decoder)
        }

        switch container.runtimeMetadata {
        case .v14(let metadata):
            return metadata
        case .v15(let metadata):
            return metadata
        case .v13:
            throw RuntimeHelperError.unexpectedMetadata
        }
    }

    public static func createTypeRegistry(
        from fileName: String,
        networkFilename: String = "common-v14",
        isOpaque: Bool = false,
        customExtensions: [TransactionExtensionCoding] = [],
        additionalNodes: [Node] = []
    ) throws -> TypeRegistryCatalog {
        let runtimeMetadata = try Self.createMetadata(for: fileName, isOpaque: isOpaque)

        let bundle: Bundle
#if SWIFT_PACKAGE
        bundle = Bundle.module
#else
        bundle = Bundle(for: self)
#endif
        guard let networkUrl = bundle.url(
                forResource: networkFilename,
                withExtension: "json"
        ) else {
            throw RuntimeHelperError.invalidCatalogNetworkName
        }

        let networdData = try Data(contentsOf: networkUrl)

        return try TypeRegistryCatalog.createFromSiDefinition(
            versioningData: networdData,
            runtimeMetadata: runtimeMetadata,
            additionalNodes: additionalNodes,
            customExtensions: customExtensions,
            customNameMapper: ScaleInfoCamelCaseMapper()
        )
    }
    
    public static func createTypeRegistryWithoutVersioning(
        from fileName: String,
        isOpaque: Bool = false,
        customExtensions: [TransactionExtensionCoding] = []
    ) throws -> TypeRegistryCatalog {
        let runtimeMetadata = try Self.createMetadata(for: fileName, isOpaque: isOpaque)
        
        let predefinedNodes = RuntimeAugmentationFactory().createSubstrateAugmentation(for: runtimeMetadata)

        return try TypeRegistryCatalog.createFromSiDefinition(
            runtimeMetadata: runtimeMetadata,
            additionalNodes: predefinedNodes.additionalNodes.nodes,
            customExtensions: customExtensions,
            customNameMapper: ScaleInfoCamelCaseMapper()
        )
    }
}
