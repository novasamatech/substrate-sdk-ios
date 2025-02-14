import XCTest
@testable import SubstrateSdk
import BigInt
#if canImport(TestHelpers)
import TestHelpers
#endif


class SignedIntNodeTests: XCTestCase {
    let typeRegistry = try! RuntimeHelper.createTypeRegistryCatalog(
        from: "default",
        networkName: "westend",
        runtimeMetadataName: "westend-metadata"
    )

    func testSignedIntEncodingDecoding() {
        let bitLengths = [8, 16, 32, 64, 128, 256]

        bitLengths.forEach { bitLength in
            let type = "I\(bitLength)"
            performEncodingDecodingTest(for: .stringValue("0"), type: type)
            performEncodingDecodingTest(for: .stringValue("1"), type: type)
            performEncodingDecodingTest(for: .stringValue("-1"), type: type)
            performEncodingDecodingTest(for: .stringValue("127"), type: type)
            performEncodingDecodingTest(for: .stringValue("-127"), type: type)
            performEncodingDecodingTest(for: .stringValue("53"), type: type)
            performEncodingDecodingTest(for: .stringValue("-53"), type: type)

            let typeValue = BigUInt(1) << (bitLength - 2)
            let positiveValue = String(typeValue)
            let negativeValue = "-" + String(typeValue)

            performEncodingDecodingTest(for: .stringValue(positiveValue), type: type)
            performEncodingDecodingTest(for: .stringValue(negativeValue), type: type)
        }
    }

    // MARK: Private

    private func performEncodingDecodingTest(for value: JSON, type: String) {
        do {
            let encodedValue = try performEncoding(value: value, type: type)
            try performDecodingTest(data: encodedValue, type: type, expected: value)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func performDecodingTest(data: Data, type: String, expected: JSON) throws {
        let decoder = try DynamicScaleDecoder(data: data, registry: typeRegistry, version: 45)
        let result = try decoder.read(type: type)
        XCTAssertEqual(expected, result)
        XCTAssertEqual(decoder.remained, 0)
    }

    private func performEncoding(value: JSON, type: String) throws -> Data {
        let encoder = DynamicScaleEncoder(registry: typeRegistry, version: 45)
        try encoder.append(json: value, type: type)
        return try encoder.encode()
    }
}
