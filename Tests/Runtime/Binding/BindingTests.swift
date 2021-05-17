import XCTest
import FearlessUtils

class BindingTests: BaseCodingTests {
    let catalog = try! RuntimeHelper.createTypeRegistryCatalog(from: "default",
                                                               networkName: "polkadot",
                                                               runtimeMetadataName: "polkadot-metadata")

    func testStructBindingCoding() throws {
        let accountData = AccountData(free: "11111111",
                                      reserved: 102,
                                      miscFrozen: 103,
                                      feeFrozen: 104)

        let expected = AccountInfo(nonce: 1,
                                   consumers: 2,
                                   providers: 3,
                                   data: accountData)

        performTest(value: expected,
                    type: "AccountInfo",
                    baseRegistryName: "default",
                    networkName: "polkadot",
                    runtimeMetadataName: "polkadot-metadata",
                    version: 28)
    }

    func testEnumBindingCoding() throws {
        let expected = RawOrigin.root

        performTest(value: expected,
                    type: "RawOrigin",
                    baseRegistryName: "default",
                    networkName: "polkadot",
                    runtimeMetadataName: "polkadot-metadata",
                    version: 28)
    }

    func testEnumValuesBindingCoding() throws {
        let expected = Reasons.misc

        performTest(value: expected,
                    type: "Reasons",
                    baseRegistryName: "default",
                    networkName: "polkadot",
                    runtimeMetadataName: "polkadot-metadata",
                    version: 28)
    }

    func testSetBindingCoding() throws {
        let expected: IdentityFields = [.legal, .fingerprint, .image]

        performTest(value: expected,
                    type: "IdentityFields",
                    baseRegistryName: "default",
                    networkName: "polkadot",
                    runtimeMetadataName: "polkadot-metadata",
                    version: 28)
    }

    func testOptionBindingCoding() throws {
        let expected = TransientValidationData(maxCodeSize: 1,
                                               maxHeadDataSize: 2,
                                               balance: 100,
                                               codeUpgradeAllowed: nil,
                                               dmqLength: 3)

        performTest(value: expected,
                    type: "TransientValidationData",
                    baseRegistryName: "default",
                    networkName: "polkadot",
                    runtimeMetadataName: "polkadot-metadata",
                    version: 28)
    }

    func testNetworkTypesDecoding() throws {
        let expected = SessionKeysPolkadot(grandpa: Data(repeating: 0, count: 32),
                                           babe: Data(repeating: 1, count: 32),
                                           imOnline: Data(repeating: 2, count: 32),
                                           authorityDiscovery: Data(repeating: 3, count: 32),
                                           parachains: Data(repeating: 4, count: 32))

        performTest(value: expected,
                    type: "SessionKeysPolkadot",
                    baseRegistryName: "default",
                    networkName: "polkadot",
                    runtimeMetadataName: "polkadot-metadata",
                    version: 28)
    }
}
