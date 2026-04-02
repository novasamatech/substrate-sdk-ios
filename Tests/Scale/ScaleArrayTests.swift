import XCTest
@testable import SubstrateSdk
import BigInt

class ScaleArrayTests: XCTestCase {
    func testEmptyArrayEncoding() throws {
        let array: [UInt8] = []
        let encoder = ScaleEncoder()
        try array.encode(scaleEncoder: encoder)

        XCTAssertEqual(encoder.encode(), Data([0]))
    }

    func testEmptyArrayDecoding() throws {
        let decoder = try ScaleDecoder(data: Data([0]))
        let array = try [UInt8](scaleDecoder: decoder)

        XCTAssertEqual(array, [])
    }

    func testArrayEncoding() throws {
        let array: [UInt8] = [1, 2, 3]
        let encoder = ScaleEncoder()
        try array.encode(scaleEncoder: encoder)

        // compact(3) = 12, then [1, 2, 3]
        XCTAssertEqual(encoder.encode(), Data([12, 1, 2, 3]))
    }

    func testArrayDecoding() throws {
        let decoder = try ScaleDecoder(data: Data([12, 1, 2, 3]))
        let array = try [UInt8](scaleDecoder: decoder)

        XCTAssertEqual(array, [1, 2, 3])
    }

    func testArrayRoundtrip() throws {
        let original: [UInt8] = [10, 20, 30, 40, 50]
        let encoder = ScaleEncoder()
        try original.encode(scaleEncoder: encoder)

        let decoder = try ScaleDecoder(data: encoder.encode())
        let decoded = try [UInt8](scaleDecoder: decoder)

        XCTAssertEqual(decoded, original)
    }

    func testMaliciousArrayLengthExceedingUIntMaxThrowsError() throws {
        // Construct compact-encoded BigUInt = 2^64 (UInt.max + 1 on 64-bit)
        // Mode 0b11 (big integer): header = (byteCount - 4) << 2 | 0b11
        // 9 bytes needed for 2^64, so header = (9 - 4) << 2 | 0b11 = 23
        // Data bytes in little-endian: [0, 0, 0, 0, 0, 0, 0, 0, 1]
        let maliciousData = Data([23, 0, 0, 0, 0, 0, 0, 0, 0, 1])

        let decoder = try ScaleDecoder(data: maliciousData)

        XCTAssertThrowsError(try [UInt8](scaleDecoder: decoder))
    }
}
