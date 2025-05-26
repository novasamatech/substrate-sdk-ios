import XCTest
@testable import SubstrateSdk
#if canImport(TestHelpers)
import TestHelpers
#endif


class RuntimeMetadataTests: XCTestCase {

    func testWestendRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "westend-metadata")
    }

    func testKusamaRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "kusama-metadata")
    }

    func testPolkadotRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "polkadot-metadata")
    }

    func testStatemineRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "statemine-metadata")
    }

    func testFetchStorage() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getStorageMetadata(in: "System", storageName: "Account"))
        XCTAssertNil(metadata.getStorageMetadata(in: "System", storageName: "account"))
    }

    func testFetchConstant() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getConstant(in: "Staking", constantName: "SlashDeferDuration"))
        XCTAssertNil(metadata.getStorageMetadata(in: "Staking", storageName: "account"))
    }

    func testFetchFunction() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getCall(from: "Staking", with: "nominate"))
        XCTAssertNil(metadata.getCall(from: "Staking", with: "account"))
    }

    func testFetchModule() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getModuleIndex("System"))
        XCTAssertNil(metadata.getModuleIndex("Undefined"))
    }

    func testFetchCallIndex() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getCallIndex(in: "Staking", callName: "bond"))
        XCTAssertNil(metadata.getCallIndex(in: "System", callName: "bond"))
    }

    // MARK: Private

    private func performRuntimeMetadataTest(filename: String) {
        let bundle: Bundle
#if SWIFT_PACKAGE
        bundle = Bundle.module
#else
        bundle = Bundle(for: type(of: self))
#endif
        do {
            guard let url = bundle
                    .url(forResource: filename, withExtension: "") else {
                XCTFail("Can't find metadata file")
                return
            }

            let hex = try String(contentsOf: url)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let expectedData = try Data(hexString: hex)

            let decoder = try ScaleDecoder(data: expectedData)
            let encoder = ScaleEncoder()

            let runtimeMetadataContainer = try RuntimeMetadataContainer(scaleDecoder: decoder)

            guard case .v13 = runtimeMetadataContainer.runtimeMetadata else {
                XCTFail("unexpected metadata")
                return
            }

            try runtimeMetadataContainer.encode(scaleEncoder: encoder)
            let resultData = encoder.encode()

            XCTAssertEqual(decoder.remained, 0)
            XCTAssertEqual(expectedData, resultData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
