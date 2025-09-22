import XCTest
@testable import SubstrateSdk

class GenericHashTests: BaseCodingTests {
    func testH160() {
        performTest(value: H160(value: Data(repeating: 7, count: 20)), type: "H160")
    }

    func testH256() {
        performTest(value: H256(value: Data(repeating: 7, count: 32)), type: "H256")
    }

    func testH512() {
        performTest(value: H512(value: Data(repeating: 7, count: 64)), type: "H512")
    }
}
