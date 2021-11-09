import XCTest
import SubstrateSdk

class RegexParserTests: XCTestCase {

    func testMatchingVectors() {
        performVectorTest(for: "Vec<SomeType>", expectedResult: "SomeType")
        performVectorTest(for: "Vec< SomeType >", expectedResult: "SomeType")
        performVectorTest(for: " Vec< SomeType > ", expectedResult: "SomeType")
        performVectorTest(for: "Vec<Vec<SomeType>>", expectedResult: "Vec<SomeType>")
        performVectorTest(for: "Vec<(TupleType1, TupleType2)>", expectedResult: "(TupleType1, TupleType2)")
    }

    func testNotMatchingVector() {
        performVectorTest(for: "Ve<SomeType>", expectedResult: nil)
        performVectorTest(for: "Vec <SomeType>", expectedResult: nil)
        performVectorTest(for: "aVec<SomeType>", expectedResult: nil)
        performVectorTest(for: "Vec<SomeType>b", expectedResult: nil)
        performVectorTest(for: "vec<SomeType>b", expectedResult: nil)
        performVectorTest(for: "aVec<SomeType>b", expectedResult: nil)
        performVectorTest(for: "Option<Vec<SomeType>>", expectedResult: nil)
        performVectorTest(for: "Vec<>", expectedResult: nil)
        performVectorTest(for: "Vec<a", expectedResult: nil)
        performVectorTest(for: "Veca>", expectedResult: nil)
    }

    func testMatchingOption() {
        performOptionTest(for: "Option<SomeType>", expectedResult: "SomeType")
        performOptionTest(for: "Option< SomeType >", expectedResult: "SomeType")
        performOptionTest(for: " Option< SomeType > ", expectedResult: "SomeType")
        performOptionTest(for: "Option<Option<SomeType>>", expectedResult: "Option<SomeType>")
        performOptionTest(for: "Option<(TupleType1, TupleType2)>", expectedResult: "(TupleType1, TupleType2)")
    }

    func testNotMatchingOption() {
        performOptionTest(for: "Opton<SomeType>", expectedResult: nil)
        performOptionTest(for: "Option <SomeType>", expectedResult: nil)
        performOptionTest(for: "aOption<SomeType>", expectedResult: nil)
        performOptionTest(for: "Option<SomeType>b", expectedResult: nil)
        performOptionTest(for: "option<SomeType>b", expectedResult: nil)
        performOptionTest(for: "aOption<SomeType>b", expectedResult: nil)
        performOptionTest(for: "Vec<Option<SomeType>>", expectedResult: nil)
        performOptionTest(for: "Option<>", expectedResult: nil)
        performOptionTest(for: "Option<a", expectedResult: nil)
        performOptionTest(for: "Optiona>", expectedResult: nil)
    }

    func testMatchingCompact() {
        performCompactTest(for: "Compact<SomeType>", expectedResult: "SomeType")
        performCompactTest(for: "Compact< SomeType >", expectedResult: "SomeType")
        performCompactTest(for: " Compact< SomeType > ", expectedResult: "SomeType")
    }

    func testNotMatchingCompact() {
        performCompactTest(for: "Compat<SomeType>", expectedResult: nil)
        performCompactTest(for: "Compact <SomeType>", expectedResult: nil)
        performCompactTest(for: "aCompact<SomeType>", expectedResult: nil)
        performCompactTest(for: "Compact<SomeType>b", expectedResult: nil)
        performCompactTest(for: "compact<SomeType>b", expectedResult: nil)
        performCompactTest(for: "aCompact<SomeType>b", expectedResult: nil)
        performCompactTest(for: "Vec<Compact<SomeType>>", expectedResult: nil)
        performCompactTest(for: "Compact<>", expectedResult: nil)
        performCompactTest(for: "Compact<a", expectedResult: nil)
        performCompactTest(for: "Compacta>", expectedResult: nil)
    }
    // MARK: Private

    private func performVectorTest(for type: String, expectedResult: String?) {
        performRegexTest(for: RegexParser.vector(),
                         type: type,
                         singleResult: expectedResult)
    }

    private func performOptionTest(for type: String, expectedResult: String?) {
        performRegexTest(for: RegexParser.option(),
                         type: type,
                         singleResult: expectedResult)
    }

    private func performCompactTest(for type: String, expectedResult: String?) {
        performRegexTest(for: RegexParser.compact(),
                         type: type,
                         singleResult: expectedResult)
    }

    private func performRegexTest(for parser: RegexParser, type: String, singleResult: String?) {
        if let expectedResult = singleResult {
            performRegexTest(for: parser, type: type, expectedResult: [expectedResult])
        } else {
            performRegexTest(for: parser, type: type, expectedResult: nil)
        }
    }

    private func performRegexTest(for parser: RegexParser, type: String, expectedResult: [String]?) {
        let result = parser.parse(json: .stringValue(type))

        if let expectedResult = expectedResult {
            XCTAssertEqual(result?.compactMap({ $0.stringValue }), expectedResult)
        } else {
            XCTAssertNil(result)
        }
    }
}
