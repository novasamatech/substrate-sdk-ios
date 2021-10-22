import XCTest
import FearlessUtils

class SubstrateJunctionFactoryTests: XCTestCase {
    func testExtractSoft() throws {
        // given

        let path = "/1"
        let data = Data([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let expectedChaincode = Chaincode(data: data,
                                          type: .soft)

        let junctionFactory = SubstrateJunctionFactory()

        // when

        let result = try junctionFactory.parse(path: path)

        // then

        XCTAssertNil(result.password)
        XCTAssertEqual(result.chaincodes, [expectedChaincode])
    }

    func testExtractHard() throws {
        // given

        let path = "//1"
        let data = Data([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let expectedChaincode = Chaincode(data: data,
                                          type: .hard)

        let junctionFactory = SubstrateJunctionFactory()

        // when

        let result = try junctionFactory.parse(path: path)

        // then

        XCTAssertNil(result.password)
        XCTAssertEqual(result.chaincodes, [expectedChaincode])
    }

    func testExtractHardSoft() throws {
        // given

        let path = "//1/2"
        let expectedChaincodes: [Chaincode] = [
            Chaincode(data: Data([1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                      type: .hard),
            Chaincode(data: Data([2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                      type: .soft),
        ]

        let junctionFactory = SubstrateJunctionFactory()

        // when

        let result = try junctionFactory.parse(path: path)

        // then

        XCTAssertNil(result.password)
        XCTAssertEqual(result.chaincodes, expectedChaincodes)
    }

    func testMissingPrefix() throws {
        try performErrorTest(path: "1/2", expectedError: .invalidStart)
        try performErrorTest(path: "hello", expectedError: .invalidStart)
    }

    // MARK: Private

    func performErrorTest(path: String, expectedError: JunctionFactoryError) throws {
        do {
            let junctionFactory = SubstrateJunctionFactory()
            _ = try junctionFactory.parse(path: path)

            XCTFail("Error expected")
        } catch {
            if let junctionError = error as? JunctionFactoryError {
                XCTAssertEqual(junctionError, expectedError)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
