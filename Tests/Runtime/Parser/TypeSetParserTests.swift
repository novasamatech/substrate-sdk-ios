import XCTest
@testable import SubstrateSdk

class TypeSetParserTests: XCTestCase {

    func testValidNumericSet() throws {
        let jsonStr =
            "{\"type\":\"set\",\"value_type\":\"u64\",\"value_list\":{\"Display\":1,\"Legal\":2,\"Web\":4,\"Riot\":8,\"Email\":16,\"PgpFingerprint\":32,\"Image\":64,\"Twitter\":128}}"

        let expectedType = "u64"
        let expectedMapping: [String: UInt64] = [
            "Display" : 1,
            "Legal": 2,
            "Web": 4,
            "Riot": 8,
            "Email": 16,
            "PgpFingerprint": 32,
            "Image": 64,
            "Twitter": 128
        ]

        try performTestNumericSetParser(input: jsonStr,
                                        expectedType: expectedType,
                                        expectedMapping: expectedMapping)
    }

    // MARK: Private

    private func performTestNumericSetParser(input: String,
                                             expectedType: String?,
                                             expectedMapping: [String: UInt64]?) throws {
        let json = try JSON.from(string: input)

        let parser = TypeSetParser.generic()

        let result = parser.parse(json: json)

        let typeResult = result?.first?.stringValue

        let valuesResult: ([String: UInt64])? = result?
            .dropFirst()
            .reduce(into: [String: UInt64]()) { ( result, item) in
                if let array = item.arrayValue,
                   array.count == 2,
                   let key = array.first?.stringValue,
                   let value: UInt64 = array.last?.unsignedIntValue {
                    result[key] = value
                }
        }

        XCTAssertEqual(expectedType, typeResult)
        XCTAssertEqual(expectedMapping, valuesResult)
    }
}
