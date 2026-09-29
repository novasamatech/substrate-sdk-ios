import Foundation
import BigInt
import Testing
@testable import SubstrateSdk
#if canImport(TestHelpers)
import TestHelpers
#endif

struct ExtrinsicExtraVersioningTests {
    private struct Fixture {
        let metadata: RuntimeMetadataV16
        let catalog: TypeRegistryCatalog

        var extraNode: ExtrinsicExtraNode {
            ExtrinsicExtraNode(runtimeMetadata: metadata, customExtensions: [])
        }

        func encode(_ extra: ExtrinsicExtra, extensionVersion: UInt8) throws -> Data {
            let encoder = DynamicScaleEncoder(registry: catalog, version: 0)
            try extraNode.encode(extra, extensionVersion: extensionVersion, encoder: encoder)
            return try encoder.encode()
        }

        func decode(_ data: Data, extensionVersion: UInt8) throws -> ExtrinsicExtra {
            let decoder = try DynamicScaleDecoder(data: data, registry: catalog, version: 0)
            return try extraNode.decode(extensionVersion: extensionVersion, decoder: decoder)
        }
    }

    // Version 0: ExtA(u8), ExtB(u32). Version 1 reorders and changes ExtB's shape: ExtB(u64), ExtA(u8).
    private func makeFixture() throws -> Fixture {
        let base = try #require(
            try PostV14RuntimeHelper.createMetadata(for: "westend-v16-metadata", isOpaque: true) as? RuntimeMetadataV16
        )

        func primitiveId(_ primitive: RuntimeTypePrimitive) throws -> SiLookupId {
            try #require(
                base.types.types.first { portable in
                    if case let .primitive(value) = portable.type.typeDefinition {
                        return value == primitive
                    }
                    return false
                }?.identifier
            )
        }

        let emptyTuple = try #require(
            base.types.types.first { portable in
                if case let .tuple(value) = portable.type.typeDefinition {
                    return value.components.isEmpty
                }
                return false
            }?.identifier
        )

        let extrinsic = ExtrinsicMetadataV16(
            versions: [4, 5],
            addressType: base.extrinsic.addressType,
            callType: base.extrinsic.callType,
            signatureType: base.extrinsic.signatureType,
            transactionExtensionsByVersion: [
                TransactionExtensionsVersionV16(extensionVersion: 0, extensionIndexes: [0, 1]),
                TransactionExtensionsVersionV16(extensionVersion: 1, extensionIndexes: [2, 0])
            ],
            transactionExtensions: [
                TransactionExtensionMetadataV16(identifier: "ExtA", type: try primitiveId(.u8), implicit: emptyTuple),
                TransactionExtensionMetadataV16(identifier: "ExtB", type: try primitiveId(.u32), implicit: emptyTuple),
                TransactionExtensionMetadataV16(identifier: "ExtB", type: try primitiveId(.u64), implicit: emptyTuple)
            ]
        )

        let metadata = RuntimeMetadataV16(
            types: base.types,
            pallets: base.pallets,
            extrinsic: extrinsic,
            apis: base.apis
        )

        let augmentation = RuntimeAugmentationFactory().createSubstrateAugmentation(for: metadata)

        let catalog = try TypeRegistryCatalog.createFromSiDefinition(
            runtimeMetadata: metadata,
            additionalNodes: augmentation.additionalNodes.nodes
        )

        return Fixture(metadata: metadata, catalog: catalog)
    }

    private func number(_ json: JSON?) -> UInt64? {
        json?.unsignedIntValue ?? json?.stringValue.flatMap { UInt64($0) }
    }

    private let extra: ExtrinsicExtra = [
        "ExtA": .stringValue("1"),
        "ExtB": .stringValue("10")
    ]

    @Test func encodesInOrderAndShapeOfRequestedVersion() throws {
        let fixture = try makeFixture()

        #expect(try fixture.encode(extra, extensionVersion: 0) == Data([0x01, 0x0a, 0, 0, 0]))
        #expect(try fixture.encode(extra, extensionVersion: 1) == Data([0x0a, 0, 0, 0, 0, 0, 0, 0, 0x01]))
    }

    @Test func decodesInOrderAndShapeOfRequestedVersion() throws {
        let fixture = try makeFixture()

        let decodedV0 = try fixture.decode(Data([0x01, 0x0a, 0, 0, 0]), extensionVersion: 0)
        #expect(number(decodedV0["ExtA"]) == 1)
        #expect(number(decodedV0["ExtB"]) == 10)

        let decodedV1 = try fixture.decode(Data([0x0a, 0, 0, 0, 0, 0, 0, 0, 0x01]), extensionVersion: 1)
        #expect(number(decodedV1["ExtA"]) == 1)
        #expect(number(decodedV1["ExtB"]) == 10)
    }

    @Test func unversionedCodingUsesDefaultVersion() throws {
        let fixture = try makeFixture()

        let encoder = DynamicScaleEncoder(registry: fixture.catalog, version: 0)
        try fixture.extraNode.accept(encoder: encoder, value: .dictionaryValue(extra))
        #expect(try encoder.encode() == Data([0x01, 0x0a, 0, 0, 0]))

        let decoder = try DynamicScaleDecoder(data: Data([0x01, 0x0a, 0, 0, 0]), registry: fixture.catalog, version: 0)
        let decoded = try fixture.extraNode.accept(decoder: decoder)
        #expect(number(decoded.ExtB) == 10)
    }

    @Test func throwsForUnsupportedExtensionVersion() throws {
        let fixture = try makeFixture()

        #expect(throws: PostV14ExtrinsicMetadataError.unsupportedExtensionVersion(2)) {
            _ = try fixture.encode(extra, extensionVersion: 2)
        }

        #expect(throws: PostV14ExtrinsicMetadataError.unsupportedExtensionVersion(2)) {
            _ = try fixture.decode(Data([0x01]), extensionVersion: 2)
        }
    }

    @Test func generalExtrinsicCodesExplicitsWithItsExtensionVersion() throws {
        let fixture = try makeFixture()

        let call = try RuntimeCall(
            moduleName: "Balances",
            callName: "transfer_allow_death",
            args: TransferArgs(dest: .accoundId(Data(repeating: 1, count: 32)), value: 1)
        ).toScaleCompatibleJSON()

        let callEncoder = DynamicScaleEncoder(registry: fixture.catalog, version: 0)
        try callEncoder.append(json: call, type: KnownType.call.name)
        let callData = try callEncoder.encode()

        let general = Extrinsic.General(extensionVersion: 1, call: call, explicits: extra)

        let encoder = DynamicScaleEncoder(registry: fixture.catalog, version: 0)
        try encoder.append(Extrinsic.generalTransaction(general), ofType: GenericType.extrinsic.name)
        let encoded = try encoder.encode()

        let body = Data([0x45, 0x01, 0x0a, 0, 0, 0, 0, 0, 0, 0, 0x01]) + callData
        let lengthEncoder = ScaleEncoder()
        try BigUInt(body.count).encode(scaleEncoder: lengthEncoder)

        #expect(encoded == lengthEncoder.encode() + body)

        let decoder = try DynamicScaleDecoder(data: encoded, registry: fixture.catalog, version: 0)
        let decoded: Extrinsic = try decoder.read(of: GenericType.extrinsic.name)

        guard case let .generalTransaction(decodedGeneral) = decoded else {
            Issue.record("expected general transaction")
            return
        }

        #expect(decodedGeneral.extensionVersion == 1)
        #expect(number(decodedGeneral.explicits["ExtA"]) == 1)
        #expect(number(decodedGeneral.explicits["ExtB"]) == 10)
    }
}
