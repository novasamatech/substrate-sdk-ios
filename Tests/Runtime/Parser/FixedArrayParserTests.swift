import XCTest
import FearlessUtils

class FixedArrayParserTests: XCTestCase {
    func testMatchingFixedArray() {
        performTest(for: "[u8;32]", expectedType: "u8", expectedLength: 32)
        performTest(for: "[U16;32]", expectedType: "U16", expectedLength: 32)
        performTest(for: "[u16; 132]", expectedType: "u16", expectedLength: 132)

        let maxLength = UInt64.max - 1
        performTest(for: "[ U16 ; \(maxLength)]", expectedType: "U16", expectedLength: maxLength)

        performTest(for: "[ U16 ; 2 ]", expectedType: "U16", expectedLength: 2)
        performTest(for: "[Type1<S1, [S2; 33]>; 1]", expectedType: "Type1<S1, [S2; 33]>", expectedLength: 1)
        performTest(for: "[u8; 0]", expectedType: "u8", expectedLength: 0)
    }

    func testNotMatchingFixedArray() {
        performTest(for: "[u8,32]", expectedType: nil, expectedLength: nil)
        performTest(for: "[u8.32]", expectedType: nil, expectedLength: nil)
        performTest(for: "[u8;32;]", expectedType: nil, expectedLength: nil)
        performTest(for: "[]", expectedType: nil, expectedLength: nil)
        performTest(for: "[u8]", expectedType: nil, expectedLength: nil)
        performTest(for: "[Type1<S1, [S2; 33]; 1]", expectedType: nil, expectedLength: nil)
    }

    // MARK: Private

    private func performTest(for type: String, expectedType: String?, expectedLength: UInt64?) {
        let parser = FixedArrayParser.generic()
        let result = parser.parse(json: .stringValue(type))

        if let expectedType = expectedType, let expectedLength = expectedLength {
            XCTAssertEqual(result?.first?.stringValue, expectedType)
            XCTAssertEqual(result?.last?.unsignedIntValue, expectedLength)
            XCTAssertEqual(result?.count, 2)
        } else {
            XCTAssertNil(result)
        }
    }
}
