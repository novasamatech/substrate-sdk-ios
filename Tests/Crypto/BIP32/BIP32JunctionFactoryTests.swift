import XCTest
import FearlessUtils

class BIP32JunctionFactoryTests: XCTestCase {
    func testExtractSoft() throws {
        // given

        let path = "/1"
        let data = Data([0, 0, 0, 0x01])
        let expectedChaincode = Chaincode(data: data,
                                          type: .soft)

        let junctionFactory = BIP32JunctionFactory()

        // when

        let result = try junctionFactory.parse(path: path)

        // then

        XCTAssertNil(result.password)
        XCTAssertEqual(result.chaincodes, [expectedChaincode])
    }

    func testExtractHard() throws {
        // given

        let path = "//1"
        let data = Data([0x80, 0, 0, 0x01])
        let expectedChaincode = Chaincode(data: data,
                                          type: .hard)

        let junctionFactory = BIP32JunctionFactory()

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
            Chaincode(data: Data([0x80, 0, 0, 0x01]),
                      type: .hard),
            Chaincode(data: Data([0, 0, 0, 0x02]),
                      type: .soft),
        ]

        let junctionFactory = BIP32JunctionFactory()

        // when

        let result = try junctionFactory.parse(path: path)

        // then

        XCTAssertNil(result.password)
        XCTAssertEqual(result.chaincodes, expectedChaincodes)
    }

    func testExtractBiggestHard() throws {
        // given

        let path = "/0//2147483647"
        let expectedChaincodes: [Chaincode] = [
            Chaincode(data: Data([0, 0, 0, 0]),
                      type: .soft),
            Chaincode(data: Data([0xFF, 0xFF, 0xFF, 0xFF]),
                      type: .hard),
        ]

        let junctionFactory = BIP32JunctionFactory()

        // when

        let result = try junctionFactory.parse(path: path)

        // then

        XCTAssertNil(result.password)
        XCTAssertEqual(result.chaincodes, expectedChaincodes)
    }

    func testMissingPrefix() throws {
        try performErrorTest(path: "1/2", expectedError: .invalidStart)
        try performErrorTest(path: "hello", expectedError: .invalidStart)
        try performBIP32ErrorTest(path: "/1/5000000000", expectedError: .invalidBIP32Junction)
        try performBIP32ErrorTest(path: "/hello", expectedError: .invalidBIP32Junction)
    }

    // MARK: Private

    func performErrorTest(path: String, expectedError: JunctionFactoryError) throws {
        do {
            let junctionFactory = BIP32JunctionFactory()
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

    func performBIP32ErrorTest(path: String, expectedError: BIP32JunctionFactoryError) throws {
        do {
            let junctionFactory = BIP32JunctionFactory()
            _ = try junctionFactory.parse(path: path)

            XCTFail("Error expected")
        } catch {
            if let junctionError = error as? BIP32JunctionFactoryError {
                XCTAssertEqual(junctionError, expectedError)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
}
