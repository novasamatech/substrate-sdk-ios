import XCTest
@testable import SubstrateSdk

class ScaleBoolOptionTests: XCTestCase {

    func testValues() throws {
        for value in ScaleBoolOption.allCases {
            XCTAssertNoThrow(try performValueTest(value))
        }
    }

    // MARK: Private

    private func performValueTest(_ expectedValue: ScaleBoolOption) throws {
        let encoder = ScaleEncoder()

        try expectedValue.encode(scaleEncoder: encoder)

        let decoder = try ScaleDecoder(data: encoder.encode())
        let value = try ScaleBoolOption(scaleDecoder: decoder)

        XCTAssertEqual(expectedValue, value)
    }
}
