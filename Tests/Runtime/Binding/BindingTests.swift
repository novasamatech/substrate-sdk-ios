import XCTest
@testable import SubstrateSdk
import BigInt
#if canImport(TestHelpers)
import TestHelpers
#endif


class BindingTests: BaseCodingTests {
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

    func testScaleInfoStructBindingCoding() throws {
        performTestScaleInfoStructBindingCoding(true)
        performTestScaleInfoStructBindingCoding(false)
    }
    
    private func performTestScaleInfoStructBindingCoding(_ shouldUseVersioning: Bool) {
        let accountData = AccountData(free: "11111111",
                                      reserved: 102,
                                      miscFrozen: 103,
                                      feeFrozen: 104)

        let expected = AccountInfoV14(
            nonce: 1,
            consumers: 2,
            providers: 3,
            sufficients: 4,
            data: accountData
        )

        performScaleInfoTest(
            value: expected,
            type: "3",
            runtimeFilename: "kusama-v14-metadata",
            shouldUseDefaultVersioning: shouldUseVersioning
        )
    }

    func testSiValidatorPrefsBindingCoding() throws {
        try performTestSiValidatorPrefsBindingCoding(true)
        try performTestSiValidatorPrefsBindingCoding(false)
    }
    
    private func performTestSiValidatorPrefsBindingCoding(_ shouldUseVersioning: Bool) throws {
        let expected = ValidatorPrefs(
            commission: BigUInt(1e+6),
            blocked: false
        )

        performScaleInfoTest(
            value: expected,
            type: "213",
            runtimeFilename: "kusama-v14-metadata",
            shouldUseDefaultVersioning: shouldUseVersioning
        )
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

    func testScaleInfoVariantNullBindingCoding() throws {
        performTestScaleInfoVariantNullBindingCoding(true)
        performTestScaleInfoVariantNullBindingCoding(false)
    }
    
    private func performTestScaleInfoVariantNullBindingCoding(_ shouldUseVersioning: Bool) {
        let expected = RawOrigin.root

        performScaleInfoTest(
            value: expected,
            type: "574",
            runtimeFilename: "kusama-v14-metadata",
            shouldUseDefaultVersioning: shouldUseVersioning
        )
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

    func testScaleInfoSetBindingCoding() throws {
        try performTestScaleInfoSetBindingCoding(true)
        try performTestScaleInfoSetBindingCoding(false)
    }
    
    func performTestScaleInfoSetBindingCoding(_ shouldUseVersioning: Bool) throws {
        let expected: IdentityFields = [.legal, .fingerprint, .image]

        performScaleInfoTest(
            value: expected,
            type: "351",
            runtimeFilename: "kusama-v14-metadata",
            shouldUseDefaultVersioning: shouldUseVersioning
        )
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

    func testOptionEnumWithVariantCoding() throws {
        let expected = FundInfo(
            retiring: false,
            depositor: Data(repeating: 0, count: 32),
            verifier: nil,
            deposit: BigUInt(10),
            raised: BigUInt(100),
            end: 1000,
            cap: BigUInt(1000),
            lastContribution: .ending(blockNumber: 32),
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

    func testScaleInfoOptionVariantCoding() throws {
        performTestScaleInfoOptionVariantCoding(true)
        performTestScaleInfoOptionVariantCoding(false)
    }
    
    private func performTestScaleInfoOptionVariantCoding(_ shouldUseVersioning: Bool) {
        let expected = FundInfoV14(
            depositor: Data(repeating: 0, count: 32),
            verifier: nil,
            deposit: BigUInt(10),
            raised: BigUInt(100),
            end: 1000,
            cap: BigUInt(1000),
            lastContribution: .never,
            firstPeriod: 32,
            lastPeriod: 40,
            trieIndex: 1
        )

        performScaleInfoTest(
            value: expected,
            type: "679",
            runtimeFilename: "kusama-v14-metadata",
            shouldUseDefaultVersioning: shouldUseVersioning
        )
    }

    func testOptionEnumWithVariantCodingAndOptionField() throws {
        try performTestOptionEnumWithVariantCodingAndOptionField(true)
        try performTestOptionEnumWithVariantCodingAndOptionField(false)
    }
    
    func performTestOptionEnumWithVariantCodingAndOptionField(_ shouldUseVersioning: Bool) throws {
        let expected = FundInfoV14(
            depositor: Data(repeating: 0, count: 32),
            verifier: MultiSigner.sr25519(Data(repeating: 1, count: 32)),
            deposit: BigUInt(10),
            raised: BigUInt(100),
            end: 1000,
            cap: BigUInt(1000),
            lastContribution: .never,
            firstPeriod: 32,
            lastPeriod: 40,
            trieIndex: 1
        )

        performScaleInfoTest(
            value: expected,
            type: "679",
            runtimeFilename: "kusama-v14-metadata",
            shouldUseDefaultVersioning: shouldUseVersioning
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
