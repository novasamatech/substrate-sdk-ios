import XCTest
import FearlessUtils
import BigInt

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

    func testOptionEnumCoding() throws {
        let expected = FundInfo(
            retiring: false,
            depositor: Data(repeating: 0, count: 32),
            verifier: nil,
            deposit: BigUInt(10),
            raised: BigUInt(100),
            end: 1000,
            cap: BigUInt(1000),
            lastContribution: .never,
            firstSlot: 32,
            lastSlot: 40,
            trieIndex: 1
        )

        performTest(value: expected,
                    type: "FundInfo",
                    baseRegistryName: "default",
                    networkName: "westend",
                    runtimeMetadataName: "westend-metadata",
                    version: 9010
        )
    }

    func testOptionTupleCoding() throws {
        performNullTest(
            type: "Option<OpenTipFinderTo225>",
            baseRegistryName: "default",
            networkName: "westend",
            runtimeMetadataName: "westend-metadata",
            version: 9010
        )
    }
}
