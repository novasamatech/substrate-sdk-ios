import XCTest
@testable import SubstrateSdk
#if canImport(TestHelpers)
import TestHelpers
#endif


class TypeRegistryCatalogTests: XCTestCase {

    func testTypeExtractedOnLastVersion() throws {
        // given

        let catalog = try RuntimeHelper.createTypeRegistryCatalog(from: "default",
                                                                  networkName: "kusama",
                                                                  runtimeMetadataName: "kusama-metadata")

        // when

        let node = catalog.node(for: "CompactAssignments", version: 2027)

        // then

        XCTAssertEqual(node?.typeName, "CompactAssignmentsFrom258")
    }

    func testTypeExtractedFromWithoutVersioning() throws {
        // give

        let catalog = try RuntimeHelper.createTypeRegistryCatalog(from: "default",
                                                                  runtimeMetadataName: "kusama-metadata")

        // when

        let node = catalog.node(for: "CompactAssignments", version: 2027)

        // then

        XCTAssertEqual(node?.typeName, "CompactAssignmentsFrom258")
    }

    func testTypeExtractedFromProperVersion() throws {
        // given

        let catalog = try RuntimeHelper.createTypeRegistryCatalog(from: "default",
                                                                  networkName: "kusama",
                                                                  runtimeMetadataName: "kusama-metadata")

        // when

        let node = catalog.node(for: "CompactAssignments", version: 2022)

        // then

        XCTAssertEqual(node?.typeName, "CompactAssignmentsTo257")
    }

    func testMetadataFallback() throws {
        // given

        let catalog = try RuntimeHelper.createTypeRegistryCatalog(from: "default",
                                                                  networkName: "kusama",
                                                                  runtimeMetadataName: "kusama-metadata")

        // when

        let node = catalog.node(for: "<Moment as hasCompact>::Type", version: 2022)

        // then

        XCTAssertEqual(node?.typeName, "Compact<Moment>")
    }
}
