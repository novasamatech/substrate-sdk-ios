import XCTest
@testable import SubstrateSdk

class TermParserTests: XCTestCase {
    func testValidTerm() {
        let expected = "AccountInfo<Balance>"
        let parser = TermParser.generic()

        let result = parser.parse(json: .stringValue(expected))

        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(expected, result?.first?.stringValue)
    }

    func testValidTermTrimmed() {
        let expected = "AccountInfo<Balance>"
        let parser = TermParser.generic()

        let result = parser.parse(json: .stringValue(" " + expected + " "))

        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(expected, result?.first?.stringValue)
    }

    func testInvalidTerm() {
        let parser = TermParser.generic()

        let result = parser.parse(json: .unsignedIntValue(1))

        XCTAssertNil(result)
    }
}
