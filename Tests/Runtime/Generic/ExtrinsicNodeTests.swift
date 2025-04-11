import XCTest
import SubstrateSdk

class ExtrinsicNodeTests: XCTestCase {
    func testExtrinsicDecodeEncode() throws {
        // given
        do {
            let expected = try Data(hexString: "0x45028400340a806419d5e278172e45cb0e50da1b031795366c99ddfe0a680bd53b142c630124d30c51db45d81caf59bdf795ca7d6122d47ec6f2979392d216ce51d551447d3ff3b61e0e2bbed3f8a19bf0199d1440f88f91ac04bcad6c67ad352456507782c500910100040300fdc41550fb5186d71cae699c31731b3e1baa10680c7bd6b3831a6d222cf4d1680700e40b5402")

            let catalog = try RuntimeHelper
                .createTypeRegistryCatalog(from: "default",
                                           networkName: "westend",
                                           runtimeMetadataName: "westend-metadata")

            let decoder = try DynamicScaleDecoder(data: expected,
                                                  registry: catalog,
                                                  version: 48)

            let extrinsic: Extrinsic = try decoder.read(of: GenericType.extrinsic.name)

            let encoder = DynamicScaleEncoder(registry: catalog, version: 48)
            try encoder.append(extrinsic, ofType: GenericType.extrinsic.name)
            let result = try encoder.encode()

            XCTAssertEqual(expected, result)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testV5ExtrinsicDecoding() throws {
        let extrinsicHex = "0xc04500b503880000040000340a806419d5e278172e45cb0e50da1b031795366c99ddfe0a680bd53b142c630700e40b5402"
        let extrinsicData = try Data(hexString: extrinsicHex)
        
        let metadata = try PostV14RuntimeHelper.createMetadata(for: "westend-v15-metadata", isOpaque: true)
        
        let augmentationFactory = RuntimeAugmentationFactory()
        let result = augmentationFactory.createSubstrateAugmentation(for: metadata)
        
        let catalog = try TypeRegistryCatalog.createFromSiDefinition(
            runtimeMetadata: metadata,
            additionalNodes: result.additionalNodes.nodes
        )
        
        let decoder = try DynamicScaleDecoder(
            data: extrinsicData,
            registry: catalog,
            version: 0
        )
        
        let extrinsic: Extrinsic = try decoder.read(of: GenericType.extrinsic.rawValue)
        
        let encoder = DynamicScaleEncoder(
            registry: catalog,
            version: 0
        )
        
        try encoder.append(extrinsic, ofType: GenericType.extrinsic.rawValue)
        
        let encodedExtrinsic = try encoder.encode()
        
        XCTAssertEqual(extrinsicData, encodedExtrinsic)
    }
}
