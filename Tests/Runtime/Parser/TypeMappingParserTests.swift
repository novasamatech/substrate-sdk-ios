import XCTest
import FearlessUtils

class TypeMappingParserTests: XCTestCase {
    func testValidStructure() throws {
        let jsonStr =
            "{\"type\":\"struct\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}"

        let expected = [["weight", "Weight"], ["class", "DispatchClass"], ["paysFee", "Pays"]]

        try performTestStructureParser(input: jsonStr, expected: expected)
    }

    func testInvalidStructureMissingValue() throws {
        let jsonStr =
            "{\"type\":\"struct\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\"],[\"paysFee\",\"Pays\"]]}"

        try performTestStructureParser(input: jsonStr, expected: nil)
    }

    func testInvalidStructureType() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}"

        try performTestStructureParser(input: jsonStr, expected: nil)
    }

    func testInvalidStructureKey() throws {
        let jsonStr =
            "{\"type\":\"struct\",\"mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}"

        try performTestStructureParser(input: jsonStr, expected: nil)
    }

    func testInvalidStructureMoreValue() throws {
        let jsonStr =
            "{\"type\":\"struct\",\"type_mapping\":[[\"weight\",\"Weight\", \"Pays\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}"

        try performTestStructureParser(input: jsonStr, expected: nil)
    }

    func testValidEnum() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"type_mapping\":[[\"Alive\",\"AliveContractInfo\"],[\"Tombstone\",\"TombstoneContractInfo\"]]}"

        let expected = [["Alive", "AliveContractInfo"], ["Tombstone", "TombstoneContractInfo"]]

        try performTestEnumParser(input: jsonStr, expected: expected)
    }

    func testInvalidEnumMissingValue() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"type_mapping\":[[\"Alive\",\"AliveContractInfo\"],[\"Tombstone\"]]}"

        try performTestEnumParser(input: jsonStr, expected: nil)
    }

    func testInvalidEnumType() throws {
        let jsonStr =
            "{\"type\":\"struct\",\"type_mapping\":[[\"Alive\",\"AliveContractInfo\"],[\"Tombstone\",\"TombstoneContractInfo\"]]}"

        try performTestEnumParser(input: jsonStr, expected: nil)
    }

    func testInvalidEnumKey() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"mapping\":[[\"Alive\",\"AliveContractInfo\"],[\"Tombstone\",\"TombstoneContractInfo\"]]}"

        try performTestEnumParser(input: jsonStr, expected: nil)
    }

    func testInvalidEnumMoreValue() throws {
        let jsonStr =
            "{\"type\":\"enum\",\"type_mapping\":[[\"Alive\",\"AliveContractInfo\"],[\"Tombstone\",\"TombstoneContractInfo\", \"Alive\"]]}"

        try performTestEnumParser(input: jsonStr, expected: nil)
    }

    // MARK: Private

    private func performTestStructureParser(input: String, expected: [[String]]?) throws {
        let json = try JSON.from(string: input)

        let parser = TypeMappingParser.structure()

        let result = parser.parse(json: json)?.map { json in
            json.arrayValue?.map { $0.stringValue }
        }

        XCTAssertEqual(expected, result)
    }

    private func performTestEnumParser(input: String, expected: [[String]]?) throws {
        let json = try JSON.from(string: input)

        let parser = TypeMappingParser.enumeration()

        let result = parser.parse(json: json)?.map { json in
            json.arrayValue?.map { $0.stringValue }
        }

        XCTAssertEqual(expected, result)
    }
}
