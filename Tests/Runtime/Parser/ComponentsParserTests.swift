import XCTest
import SubstrateSdk

class ComponentsParserTests: XCTestCase {

    func testMatchingTuples() {
        performTupleTest(for: "(Type1,Type2)", expectedResult: ["Type1", "Type2"])
        performTupleTest(for: "(Type1<S1, S2>,Type2<(S1, S2)>)", expectedResult: ["Type1<S1, S2>", "Type2<(S1, S2)>"])
        performTupleTest(for: "(Type1<S1, S2>,Type2<(S1, S2)>,T1)", expectedResult: ["Type1<S1, S2>", "Type2<(S1, S2)>", "T1"])

        performTupleTest(for: " (Type1<S1, S2>, Type2<(S1, S2)>) ", expectedResult: ["Type1<S1, S2>", "Type2<(S1, S2)>"])

        performTupleTest(for: "( Type1<S1, S2>, Type2<(S1, S2)> )", expectedResult: ["Type1<S1, S2>", "Type2<(S1, S2)>"])
    }

    func testNotMatchingTuples() {
        performTupleTest(for: "Type1<S1, S2>,Type2<(S1, S2)>", expectedResult: nil)
        performTupleTest(for: "(Type1<S1, S2>,Type2<(S1, S2)>", expectedResult: nil)
        performTupleTest(for: "(Type1<S1, S2>,,Type2<(S1, S2)>)", expectedResult: nil)
        performTupleTest(for: "(Type1<S1, S2>,Type2<(S1, S2)>,)", expectedResult: nil)
        performTupleTest(for: "(Type1<S1, S2,Type2<(S1, S2)>)", expectedResult: nil)
        performTupleTest(for: "(Type1<S1, S2>,Type2<(S1, S2>)", expectedResult: nil)
    }

    // MARK: Private

    private func performTupleTest(for type: String, expectedResult: [String]?) {
        performComponentsTest(for: ComponentsParser.tuple(),
                              type: type,
                              expectedResult: expectedResult)
    }

    private func performComponentsTest(for parser: ComponentsParser,
                                       type: String,
                                       expectedResult: [String]?) {
        let result = parser.parse(json: .stringValue(type))

        if let expectedResult = expectedResult {
            let actualResult = result?.compactMap { $0.stringValue }
            XCTAssertEqual(actualResult, expectedResult)
        } else {
            XCTAssertNil(result)
        }
    }
}
