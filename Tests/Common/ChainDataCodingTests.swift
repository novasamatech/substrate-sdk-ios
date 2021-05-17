import XCTest
import FearlessUtils

class ChainDataCodingTests: BaseCodingTests {
    func testNone() {
        performTest(chainData: .none)
    }

    func testRawData() {
        performTest(chainData: .raw(data: Data(repeating: 7, count: 16)))
    }

    func testKeccak() {
        performTest(chainData: .keccak256(data: H256(value: Data(repeating: 8, count: 32))))
    }

    func testShaThree() {
        performTest(chainData: .shaThree256(data: H256(value: Data(repeating: 8, count: 32))))
    }

    func testSha256() {
        performTest(chainData: .sha256(data: H256(value: Data(repeating: 8, count: 32))))
    }

    private func performTest(chainData: ChainData) {
        performTest(value: chainData, type: "Data")
    }
}
