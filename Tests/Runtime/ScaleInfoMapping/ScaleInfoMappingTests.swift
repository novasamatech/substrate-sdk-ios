import XCTest
import SubstrateSdk

class ScaleInfoMappingTests: XCTestCase {

    func testCamelCaseMapping() throws {
        let mapper = ScaleInfoCamelCaseMapper()

        XCTAssertEqual("miscFrozen", mapper.map(name: "misc_frozen"))
        XCTAssertEqual("feeFrozenMiscFrozen", mapper.map(name: "fee_frozen_misc_frozen"))
        XCTAssertEqual("Fee", mapper.map(name: "Fee"))
        XCTAssertEqual("miscFrozen", mapper.map(name: "miscFrozen"))
        XCTAssertEqual("", mapper.map(name: ""))
    }
}
