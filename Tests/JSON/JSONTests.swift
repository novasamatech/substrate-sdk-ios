import XCTest
import SubstrateSdk

class JSONTests: XCTestCase {

    func testUnsignedInt () throws {
        let expected: UInt64 = 10000
        let jsonStr = "{\"key\": \(expected)}"

        let json = try JSON.from(string: jsonStr)

        XCTAssertEqual(json.key?.unsignedIntValue, expected)
    }

    func testSignedInt () throws {
        let expected: Int64 = -10000
        let jsonStr = "{\"key\": \(expected)}"

        let json = try JSON.from(string: jsonStr)

        XCTAssertEqual(json.key?.signedIntValue, expected)
    }
}
