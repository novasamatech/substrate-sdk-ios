import XCTest
@testable import SubstrateSdk
import BigInt

class ScaleStringTests: XCTestCase {
    private struct TestExample {
        let value: String
        let result: Data
    }

    private let testVectors: [TestExample] = [
        TestExample(value: "asdadad", result: Data([28]) + "asdadad".data(using: .utf8)!),
    ]

    func testEncoding() throws {
        for test in testVectors {
            let encoder = ScaleEncoder()
            try test.value.encode(scaleEncoder: encoder)

            XCTAssertEqual(encoder.encode(), test.result)
        }
    }

    func testDecoding() throws {
        for test in testVectors {
            let decoder = try ScaleDecoder(data: test.result)
            let value = try String(scaleDecoder: decoder)

            XCTAssertEqual(value, test.value)
        }
    }

    func testMaliciousStringLengthExceedingIntMaxThrowsError() throws {
        // Compact-encoded BigUInt = 2^64 (exceeds Int.max)
        // Mode 0b11: header = (9 - 4) << 2 | 0b11 = 23
        // Followed by 9 bytes in little-endian representing 2^64
        let maliciousData = Data([23, 0, 0, 0, 0, 0, 0, 0, 0, 1])

        let decoder = try ScaleDecoder(data: maliciousData)

        XCTAssertThrowsError(try String(scaleDecoder: decoder))
    }
}
