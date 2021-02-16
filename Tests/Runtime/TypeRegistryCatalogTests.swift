import XCTest
import FearlessUtils

class TypeRegistryCatalogTests: XCTestCase {
    func testWestendCatalog() throws {
        performTestNetworkCatalog(for: "default",
                                  networkName: "westend",
                                  metadataName: "westend-metadata")
    }

    func testKusamaCatalog() throws {
        performTestNetworkCatalog(for: "default",
                                  networkName: "kusama",
                                  metadataName: "kusama-metadata")
    }

    func testPolkadotCatalog() throws {
        performTestNetworkCatalog(for: "default",
                                  networkName: "polkadot",
                                  metadataName: "polkadot-metadata")
    }

    func testRuntimeMetadataReplcement() throws {
        // given

        let initialCatalog = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "polkadot",
                                       runtimeMetadataName: "test-metadata")

        let expectedCatalog = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "polkadot",
                                       runtimeMetadataName: "polkadot-metadata")

        // when

        let newRuntimeMetadata = try RuntimeHelper.createRuntimeMetadata("polkadot-metadata")

        guard
            let actualCatalog = try initialCatalog.replacingRuntimeMetadata(newRuntimeMetadata)
                as? TypeRegistryCatalog else {
            XCTFail("Unexpected catalog")
            return
        }

        // then

        XCTAssertEqual(expectedCatalog.baseRegistry.registeredTypeNames,
                       actualCatalog.baseRegistry.registeredTypeNames)

        XCTAssertEqual(expectedCatalog.versionedRegistries.mapValues({ $0.registeredTypeNames }),
                       actualCatalog.versionedRegistries.mapValues({ $0.registeredTypeNames }))

        XCTAssertEqual(expectedCatalog.versionedTypes, actualCatalog.versionedTypes)

        XCTAssertEqual(expectedCatalog.runtimeMetadataRegistry.registeredTypeNames,
                       expectedCatalog.runtimeMetadataRegistry.registeredTypeNames)
    }

    // MARK: Private

    func performTestNetworkCatalog(for baseName: String,
                                   networkName: String,
                                   metadataName: String) {
        do {
            let registry = try RuntimeHelper.createTypeRegistryCatalog(from: baseName,
                                                                       networkName: networkName, runtimeMetadataName: metadataName)

            XCTAssertTrue(!registry.baseRegistry.registeredTypes.isEmpty)
            XCTAssertTrue(!registry.versionedRegistries.isEmpty)
            XCTAssertTrue(!registry.versionedTypes.isEmpty)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
