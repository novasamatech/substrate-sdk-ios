import XCTest
import FearlessUtils

class TypeValuesParserTests: XCTestCase {
    func testValidValuesList() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"value_list\":[\"Normal\",\"Operational\",\"Mandatory\"]}"

        let expected = ["Normal", "Operational", "Mandatory"]

        try performTestValuesParser(input: jsonStr, expected: expected)
    }

    func testInvalidValuesListNumbers() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"value_list\":[1, 2]}"

        try performTestValuesParser(input: jsonStr, expected: nil)
    }

    func testInvalidValuesListType() throws {
        let jsonStr =
            "{\"type\":\"struct\",\"value_list\":[\"Normal\",\"Operational\",\"Mandatory\"]}"

        try performTestValuesParser(input: jsonStr, expected: nil)
    }

    func testInvalidValuesListKey() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"list\":[\"Normal\",\"Operational\",\"Mandatory\"]}"

        try performTestValuesParser(input: jsonStr, expected: nil)
    }


    // MARK: Private

    private func performTestValuesParser(input: String, expected: [String]?) throws {
        let json = try JSON.from(string: input)

        let parser = TypeValuesParser.enumeration()

        let result = parser.parse(json: json)?.compactMap { $0.stringValue }

        XCTAssertEqual(expected, result)
    }
}
