import XCTest
import SubstrateSdk

class AddressQRDecoderTests: XCTestCase {

    func testValidSubstrateAddressDecoding() throws {
        // given

        let expectedAddress = "5DXZzrDxHbkQov4QBAY4TjpwnHCMrKXkomTnKSw8UArBEY5v"
        let encodedAddress = expectedAddress.data(using: .utf8)!

        // when

        let actualAddress = try AddressQRDecoder(addressFormat: .substrate(type: 42))
            .decode(data: encodedAddress)

        // then

        XCTAssertEqual(expectedAddress, actualAddress)
    }

    func testValidEthereumAddressDecoding() throws {
        // given

        let expectedAddress = "0x032edaf9e591ee27f3c69c36221e3c54c38088ef"
        let encodedAddress = expectedAddress.data(using: .utf8)!

        // when

        let actualAddress = try AddressQRDecoder(addressFormat: .ethereum).decode(data: encodedAddress)

        // then

        XCTAssertEqual(expectedAddress, actualAddress)
    }

    func testInvalidSubstrateAddressDecoding() throws {
        do {
            let expectedAddress = "5DXZzrDxHCkQov4QBAY4TjpwnHCMrKXkomTnKSw8UArBEY5v"
            let encodedAddress = expectedAddress.data(using: .utf8)!

            _ = try AddressQRDecoder(addressFormat: .substrate(type: 42)).decode(data: encodedAddress)

            XCTFail("Error expected")

        } catch {
            let isInvalidAddressError = (error as? AddressQRCoderError) == .invalidAddress

            XCTAssertTrue(isInvalidAddressError)
        }
    }

    func testInvalidEthereumAddressDecoding() throws {
        do {
            let expectedAddress = "0x032edaf9e591ee27c36221e3c54c38088ef"
            let encodedAddress = expectedAddress.data(using: .utf8)!

            _ = try AddressQRDecoder(addressFormat: .ethereum).decode(data: encodedAddress)

            XCTFail("Error expexted")
        } catch {
            let isInvalidAddressError = (error as? AddressQRCoderError) == .invalidAddress

            XCTAssertTrue(isInvalidAddressError)
        }
    }
}
