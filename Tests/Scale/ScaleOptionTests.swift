import XCTest
import SubstrateSdk

class ScaleOptionTests: XCTestCase {
    func testOptionString() {
        XCTAssertNoThrow(try performTest(ScaleOption.some(value: "Kusama")))
    }

    func testNone() {
        XCTAssertNoThrow(try performTest(ScaleOption<String>.none))
    }

    // MARK: Private

    private func performTest<T: ScaleCodable & Equatable>(_ expectedValue: ScaleOption<T>) throws {
        let encoder = ScaleEncoder()

        try expectedValue.encode(scaleEncoder: encoder)

        let decoder = try ScaleDecoder(data: encoder.encode())
        let value = try ScaleOption<T>(scaleDecoder: decoder)

        XCTAssertEqual(expectedValue, value)
    }
}
