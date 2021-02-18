import XCTest
import FearlessUtils

class BindingTests: XCTestCase {
    let catalog = try! RuntimeHelper.createTypeRegistryCatalog(from: "default",
                                                               networkName: "polkadot",
                                                               runtimeMetadataName: "polkadot-metadata")

    func testStructBindingCoding() throws {
        // given

        let accountData = AccountData(free: "11111111",
                                      reserved: 102,
                                      miscFrozen: 103,
                                      feeFrozen: 104)

        let expected = AccountInfo(nonce: 1,
                                   consumers: 2,
                                   providers: 3,
                                   data: accountData)

        // when

        let encoder = DynamicScaleEncoder(registry: catalog, version: 28)

        try encoder.append(expected, ofType: "AccountInfo")
        let data = try encoder.encode()

        let decoder = try DynamicScaleDecoder(data: data,
                                              registry: catalog,
                                              version: 28)

        let actual: AccountInfo = try decoder.read(of: "AccountInfo")

        // then

        XCTAssertEqual(expected, actual)
    }

    func testEnumBindingCoding() throws {
        do {
            // given

            let expected = RawOrigin.root

            // when

            let encoder = DynamicScaleEncoder(registry: catalog, version: 28)

            try encoder.append(expected, ofType: "RawOrigin")
            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data,
                                                  registry: catalog,
                                                  version: 28)

            let actual: RawOrigin = try decoder.read(of: "RawOrigin")

            // then

            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEnumValuesBindingCoding() throws {
        do {
            // given

            let expected = Reasons.misc

            // when

            let encoder = DynamicScaleEncoder(registry: catalog, version: 28)

            try encoder.append(expected, ofType: "Reasons")
            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data,
                                                  registry: catalog,
                                                  version: 28)

            let actual: Reasons = try decoder.read(of: "Reasons")

            // then

            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSetBindingCoding() throws {
        do {
            // given

            let expected: IdentityFields = [.legal, .fingerprint, .image]

            // when

            let encoder = DynamicScaleEncoder(registry: catalog, version: 28)

            try encoder.append(expected, ofType: "IdentityFields")
            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data,
                                                  registry: catalog,
                                                  version: 28)

            let actual: IdentityFields = try decoder.read(of: "IdentityFields")

            // then

            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testOptionBindingCoding() throws {
        do {
            // given

            let expected = TransientValidationData(maxCodeSize: 1,
                                                   maxHeadDataSize: 2,
                                                   balance: 100,
                                                   codeUpgradeAllowed: nil,
                                                   dmqLength: 3)

            // when

            let encoder = DynamicScaleEncoder(registry: catalog, version: 28)

            try encoder.append(expected, ofType: "TransientValidationData")
            let data = try encoder.encode()

            let decoder = try DynamicScaleDecoder(data: data,
                                                  registry: catalog,
                                                  version: 28)

            let actual: TransientValidationData = try decoder.read(of: "TransientValidationData")

            // then

            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
