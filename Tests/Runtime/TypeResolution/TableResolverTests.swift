import XCTest
import SubstrateSdk

class TableResolverTests: XCTestCase {

    func testSuccessfullReplacement() {
        // given

        let resolver = TableResolver.noise()
        let searchingType = "<Lookup as StaticLookup>::Source"
        let expectedType = "LookupSource"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Type1", "Type2", expectedType])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testNoMatching() {
        // given

        let resolver = TableResolver.noise()
        let searchingType = "<Lookup as StaticLookup>::Source"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Type1", "Type2", "Source"])

        // then

        XCTAssertNil(result)
    }
}
