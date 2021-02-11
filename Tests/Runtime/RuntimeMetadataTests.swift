import XCTest
import FearlessUtils

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

            let runtimeMetadata = try RuntimeMetadata(scaleDecoder: decoder)

            try runtimeMetadata.encode(scaleEncoder: encoder)
            let resultData = encoder.encode()

            XCTAssertEqual(decoder.remained, 0)
            XCTAssertEqual(expectedData, resultData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
