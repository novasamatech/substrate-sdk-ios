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

        measure {
            performTestNetworkCatalog(for: baseUrl, networkURL: westendUrl)
        }
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

        measure {
            performTestNetworkCatalog(for: baseUrl, networkURL: kusamaUrl)
        }
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

        measure {
            performTestNetworkCatalog(for: baseUrl, networkURL: polkadotUrl)
        }
    }

    // MARK: Private

    func performTestNetworkCatalog(for baseUrl: URL, networkURL: URL) {
        do {
            let baseData = try Data(contentsOf: baseUrl)
            let networdData = try Data(contentsOf: networkURL)
            let registry = try TypeRegistryCatalog.createFromBaseTypeDefinition(baseData,
                                                                                networkDefinitionData: networdData)

            XCTAssertTrue(!registry.baseRegistry.registeredTypes.isEmpty)
            XCTAssertTrue(!registry.versionedRegistries.isEmpty)
            XCTAssertTrue(!registry.versionedTypes.isEmpty)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
