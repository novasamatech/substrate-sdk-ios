import Testing
@testable import SubstrateSdk

struct ExtrinsicMetadataV16VersioningTests {
    private func makeMetadata() -> ExtrinsicMetadataV16 {
        let pool = [
            TransactionExtensionMetadataV16(identifier: "CheckNonce", type: 10, implicit: 110),
            TransactionExtensionMetadataV16(identifier: "ChargeTransactionPayment", type: 11, implicit: 111),
            TransactionExtensionMetadataV16(identifier: "RestrictOrigin", type: 12, implicit: 112),
            TransactionExtensionMetadataV16(identifier: "ChargePGAS", type: 13, implicit: 113)
        ]

        let byVersion = [
            TransactionExtensionsVersionV16(extensionVersion: 0, extensionIndexes: [0, 1]),
            TransactionExtensionsVersionV16(extensionVersion: 1, extensionIndexes: [2, 0, 3])
        ]

        return ExtrinsicMetadataV16(
            versions: [4, 5],
            addressType: 0,
            callType: 0,
            signatureType: 0,
            transactionExtensionsByVersion: byVersion,
            transactionExtensions: pool
        )
    }

    @Test func exposesSupportedFormatAndExtensionVersions() {
        let metadata = makeMetadata()

        #expect(metadata.supportedFormatVersions == [4, 5])
        #expect(metadata.supportedExtensionVersions == [0, 1])
    }

    @Test func resolvesVersionZeroInDeclaredOrder() throws {
        let metadata = makeMetadata()

        let extensions = try metadata.signedExtensions(forExtensionVersion: 0)

        #expect(extensions.map(\.identifier) == ["CheckNonce", "ChargeTransactionPayment"])
        // resolved through the pool, not the flat list
        #expect(extensions.map(\.type) == [10, 11])
        #expect(extensions.map(\.additionalSigned) == [110, 111])
    }

    @Test func resolvesVersionOneWithDifferentSetAndOrder() throws {
        let metadata = makeMetadata()

        let extensions = try metadata.signedExtensions(forExtensionVersion: 1)

        #expect(extensions.map(\.identifier) == ["RestrictOrigin", "CheckNonce", "ChargePGAS"])
        #expect(extensions.map(\.type) == [12, 10, 13])
    }

    @Test func throwsForUnsupportedExtensionVersion() {
        let metadata = makeMetadata()

        #expect(throws: PostV14ExtrinsicMetadataError.unsupportedExtensionVersion(2)) {
            _ = try metadata.signedExtensions(forExtensionVersion: 2)
        }
    }

    @Test func throwsForCorruptExtensionIndex() {
        let metadata = ExtrinsicMetadataV16(
            versions: [5],
            addressType: 0,
            callType: 0,
            signatureType: 0,
            transactionExtensionsByVersion: [
                TransactionExtensionsVersionV16(extensionVersion: 0, extensionIndexes: [99])
            ],
            transactionExtensions: [
                TransactionExtensionMetadataV16(identifier: "CheckNonce", type: 10, implicit: 110)
            ]
        )

        #expect(throws: PostV14ExtrinsicMetadataError.invalidExtensionIndex(99)) {
            _ = try metadata.signedExtensions(forExtensionVersion: 0)
        }
    }

    // The flat signedExtensions (used by the V4 path / back-compat) still returns the whole pool.
    @Test func flatSignedExtensionsReturnsWholePool() {
        let metadata = makeMetadata()

        #expect(
            metadata.signedExtensions.map(\.identifier)
                == ["CheckNonce", "ChargeTransactionPayment", "RestrictOrigin", "ChargePGAS"]
        )
    }
}
