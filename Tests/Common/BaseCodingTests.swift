import XCTest
import SubstrateSdk

class BaseCodingTests: XCTestCase {
    func performTest<T: Codable & Equatable>(value: T,
                                                     type: String,
                                                     baseRegistryName: String = "default",
                                                     networkName: String = "westend",
                                                     runtimeMetadataName: String = "westend-metadata",
                                                     version: UInt64 = 48) {
        do {
            let catalog = try RuntimeHelper.createTypeRegistryCatalog(from: baseRegistryName,
                                                                      networkName: networkName,
                                                                      runtimeMetadataName: runtimeMetadataName)

            let encoder = DynamicScaleEncoder(registry: catalog, version: version)
            try encoder.append(value, ofType: type)

            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data, registry: catalog, version: version)

            let decodedValue: T = try decoder.read(of: type)

            XCTAssertEqual(decodedValue, value)
            XCTAssert(decoder.remained == 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func performNullTest(
        type: String,
        baseRegistryName: String = "default",
        networkName: String = "westend",
        runtimeMetadataName: String = "westend-metadata",
        version: UInt64 = 48
    ) {
        do {
            let catalog = try RuntimeHelper.createTypeRegistryCatalog(from: baseRegistryName,
                                                                      networkName: networkName,
                                                                      runtimeMetadataName: runtimeMetadataName)

            let encoder = DynamicScaleEncoder(registry: catalog, version: version)
            try encoder.append(json: .null, type: type)

            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data, registry: catalog, version: version)

            let decodedJson = try decoder.read(type: type)

            XCTAssertTrue(decodedJson.isNull)
            XCTAssert(decoder.remained == 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func performScaleInfoTest<T: Codable & Equatable>(
        value: T,
        type: String,
        runtimeFilename: String = "westend-v14-metadata"
    ) {
        do {
            let registry = try ScaleInfoHelper.createTypeRegistry(from: runtimeFilename)

            let encoder = DynamicScaleEncoder(registry: registry, version: 0)
            try encoder.append(value, ofType: type)

            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data, registry: registry, version: 0)

            let decodedValue: T = try decoder.read(of: type)

            XCTAssertEqual(decodedValue, value)
            XCTAssert(decoder.remained == 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
