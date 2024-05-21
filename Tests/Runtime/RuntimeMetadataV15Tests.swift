import XCTest
import SubstrateSdk

final class RuntimeMetadataV15Tests: XCTestCase {
    func testPolkadotV15MetadataParsing() {
        performOpaqueV15MetadataTest(filename: "polkadot-v15")
    }
    
    private func performOpaqueV15MetadataTest(filename: String) {
        do {
            guard let url = Bundle(for: type(of: self))
                    .url(forResource: filename, withExtension: "") else {
                XCTFail("Can't find metadata file")
                return
            }

            let hex = try String(contentsOf: url)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let expectedData = try Data(hexString: hex)

            let runtimeMetadataContainer = try RuntimeMetadataContainer.createFromOpaque(data: expectedData)

            guard case .v15 = runtimeMetadataContainer.runtimeMetadata else {
                XCTFail("unexpected metadata")
                return
            }

            let encoder = ScaleEncoder()
            try runtimeMetadataContainer.encode(scaleEncoder: encoder)
            let resultData = encoder.encode()

            XCTAssertEqual(Data(expectedData.suffix(resultData.count)), resultData)
            
            UIPasteboard.general.string = resultData.toHex()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
