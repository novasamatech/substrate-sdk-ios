import XCTest
import FearlessUtils

class RuntimeMetadataV14Tests: XCTestCase {
    func testWestendMetadataParsing() {
        performRuntimeMetadataTest(filename: "westend-v14-metadata")
    }

    func testKusamaMetadataParsing() {
        performRuntimeMetadataTest(filename: "kusama-v14-metadata")
    }

    func testPolkadotMetadataParsing() {
        performRuntimeMetadataTest(filename: "polkadot-v14-metadata")
    }

    // MARK: Private

    private func performRuntimeMetadataTest(filename: String) {
        do {
            guard let url = Bundle(for: type(of: self))
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

            guard case .v14 = runtimeMetadataContainer.runtimeMetadata else {
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
