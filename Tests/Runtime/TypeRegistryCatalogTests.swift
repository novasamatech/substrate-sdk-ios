import XCTest
import FearlessUtils

class TypeRegistryCatalogTests: XCTestCase {
    func testWestendCatalog() throws {
        guard let baseUrl = Bundle(for: type(of: self)).url(forResource: "default", withExtension: "json") else {
            XCTFail("Can't find default.json")
            return
        }

        guard let westendUrl = Bundle(for: type(of: self)).url(forResource: "westend", withExtension: "json") else {
            XCTFail("Can't find westend.json")
            return
        }

        guard let metadataUrl = Bundle(for: type(of: self))
                .url(forResource: "westend-metadata", withExtension: "") else {
            XCTFail("Can't find metadata file")
            return
        }

        performTestNetworkCatalog(for: baseUrl,
                                  networkURL: westendUrl,
                                  metadataURL: metadataUrl)
    }

    func testKusamaCatalog() throws {
        guard let baseUrl = Bundle(for: type(of: self)).url(forResource: "default", withExtension: "json") else {
            XCTFail("Can't find default.json")
            return
        }

        guard let kusamaUrl = Bundle(for: type(of: self)).url(forResource: "kusama", withExtension: "json") else {
            XCTFail("Can't find westend.json")
            return
        }

        guard let metadataUrl = Bundle(for: type(of: self))
                .url(forResource: "kusama-metadata", withExtension: "") else {
            XCTFail("Can't find metadata file")
            return
        }

        performTestNetworkCatalog(for: baseUrl,
                                  networkURL: kusamaUrl,
                                  metadataURL: metadataUrl)
    }

    func testPolkadotCatalog() throws {
        guard let baseUrl = Bundle(for: type(of: self)).url(forResource: "default", withExtension: "json") else {
            XCTFail("Can't find default.json")
            return
        }

        guard let polkadotUrl = Bundle(for: type(of: self)).url(forResource: "kusama", withExtension: "json") else {
            XCTFail("Can't find westend.json")
            return
        }

        guard let metadataUrl = Bundle(for: type(of: self))
                .url(forResource: "polkadot-metadata", withExtension: "") else {
            XCTFail("Can't find metadata file")
            return
        }

        performTestNetworkCatalog(for: baseUrl,
                                  networkURL: polkadotUrl,
                                  metadataURL: metadataUrl)
    }

    // MARK: Private

    func performTestNetworkCatalog(for baseURL: URL,
                                   networkURL: URL,
                                   metadataURL: URL) {
        do {
            let baseData = try Data(contentsOf: baseURL)
            let networdData = try Data(contentsOf: networkURL)

            let hex = try String(contentsOf: metadataURL)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let expectedData = try Data(hexString: hex)

            let decoder = try ScaleDecoder(data: expectedData)
            let runtimeMetadata = try RuntimeMetadata(scaleDecoder: decoder)

            let registry = try TypeRegistryCatalog
                .createFromBaseTypeDefinition(baseData,
                                              networkDefinitionData: networdData,
                                              runtimeMetadata: runtimeMetadata,
                                              version: 45)

            XCTAssertTrue(!registry.baseRegistry.registeredTypes.isEmpty)
            XCTAssertTrue(!registry.versionedRegistries.isEmpty)
            XCTAssertTrue(!registry.versionedTypes.isEmpty)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
