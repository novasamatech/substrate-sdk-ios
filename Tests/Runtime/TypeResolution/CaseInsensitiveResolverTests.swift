import XCTest
import SubstrateSdk

class CaseInsensitiveResolverTests: XCTestCase {
    func testCaseInsensitiveSuccessResolution() {
        // given

        let resolver = CaseInsensitiveResolver()
        let searchingType = "Bidkind<Type>"
        let expectedType = "BidKind<Type>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Type1", "Type2", expectedType])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testCaseInsensitiveUnsucessResolution() {
        // given

        let resolver = CaseInsensitiveResolver()
        let searchingType = "Bidkind<Type>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Type1", "Type2", "BidKind"])

        // then

        XCTAssertNil(result)
    }
}
