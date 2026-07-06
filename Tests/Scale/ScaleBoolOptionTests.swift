import XCTest
@testable import SubstrateSdk

class ScaleBoolOptionTests: XCTestCase {

    func testValues() throws {
        for value in ScaleBoolOption.allCases {
            XCTAssertNoThrow(try performValueTest(value))
        }
    }

    /// Canonical SCALE encoding for optional booleans:
    /// None -> 0x00, Some(true) -> 0x01, Some(false) -> 0x02
    func testEncodesToCanonicalWireFormat() throws {
        try performEncodingTest(value: .none, expectedByte: 0)
        try performEncodingTest(value: .valueTrue, expectedByte: 1)
        try performEncodingTest(value: .valueFalse, expectedByte: 2)
    }

    func testDecodesFromCanonicalWireFormat() throws {
        try performDecodingTest(byte: 0, expectedValue: .none)
        try performDecodingTest(byte: 1, expectedValue: .valueTrue)
        try performDecodingTest(byte: 2, expectedValue: .valueFalse)
    }

    func testDecodingInvalidByteThrows() throws {
        let decoder = try ScaleDecoder(data: Data([3]))

        XCTAssertThrowsError(try ScaleBoolOption(scaleDecoder: decoder))
    }

    // MARK: Private

    private func performValueTest(_ expectedValue: ScaleBoolOption) throws {
        let encoder = ScaleEncoder()

        try expectedValue.encode(scaleEncoder: encoder)

        let decoder = try ScaleDecoder(data: encoder.encode())
        let value = try ScaleBoolOption(scaleDecoder: decoder)

        XCTAssertEqual(expectedValue, value)
    }

    private func performEncodingTest(value: ScaleBoolOption, expectedByte: UInt8) throws {
        let encoder = ScaleEncoder()

        try value.encode(scaleEncoder: encoder)

        XCTAssertEqual(encoder.encode(), Data([expectedByte]))
    }

    private func performDecodingTest(byte: UInt8, expectedValue: ScaleBoolOption) throws {
        let decoder = try ScaleDecoder(data: Data([byte]))

        let value = try ScaleBoolOption(scaleDecoder: decoder)

        XCTAssertEqual(value, expectedValue)
    }
}
