import XCTest
import FearlessUtils
import IrohaCrypto

typealias ExtrinsicBuilderClosure = (ExtrinsicBuilderProtocol) throws -> ExtrinsicBuilderProtocol

class ExtrinsicBuilderTests: XCTestCase {
    func testExtrinsicWithBatchCall() {
        let genesisHash = Data(repeating: 0, count: 32).toHex(includePrefix: true)
        let specVersion: UInt32 = 48

        do {
            let account1 = Data(repeating: 1, count: 32)
            let account2 = Data(repeating: 2, count: 32)

            let args1 = TransferArgs(dest: .accoundId(account1), value: 1)
            let call1 = RuntimeCall(moduleName: "Balances",
                                    callName: "transfer",
                                    args: args1)

            let args2 = TransferArgs(dest: .accoundId(account2), value: 2)
            let call2 = RuntimeCall(moduleName: "Balances",
                                    callName: "transfer",
                                    args: args2)

            let closure: ExtrinsicBuilderClosure = { builder in
                return try builder
                    .adding(call: call1)
                    .adding(call: call2)
            }

            let expectedJsonCalls = try [call1, call2].toScaleCompatibleJSON()
            let expectedCall = try RuntimeCall(moduleName: KnowRuntimeModule.Utitlity.name,
                                               callName: KnowRuntimeModule.Utitlity.batch,
                                               args: BatchArgs(calls: expectedJsonCalls.arrayValue!))
                                .toScaleCompatibleJSON()

            try setupSignedExtrinsicBuilderTest("default",
                                                networkName: "westend",
                                                metadataName: "westend-metadata",
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: expectedCall)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExtrinsicWithSingleCall() {
        let genesisHash = Data(repeating: 0, count: 32).toHex(includePrefix: true)
        let specVersion: UInt32 = 48

        do {
            let account = Data(repeating: 1, count: 32)

            let args = TransferArgs(dest: .accoundId(account), value: 1)
            let call = RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)

            let closure: ExtrinsicBuilderClosure = { builder in
                return try builder.adding(call: call)
            }

            let expectedCall = try call.toScaleCompatibleJSON()

            try setupSignedExtrinsicBuilderTest("default",
                                                networkName: "westend",
                                                metadataName: "westend-metadata",
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: expectedCall)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnsignedExtrinsic() throws {
        do {
            // given
            let genesisHash = "0xe143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e"
            let specVersion: UInt32 = 48

            let catalog = try RuntimeHelper
                .createTypeRegistryCatalog(from: "default",
                                           networkName: "westend",
                                           runtimeMetadataName: "westend-metadata")
            let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

            let encoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

            let accountId = Data(repeating: 0, count: 32)
            let args = TransferArgs(dest: .accoundId(accountId), value: 1)
            let call = RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)

            let extrinsicData = try ExtrinsicBuilder(specVersion: specVersion,
                                                     transactionVersion: 4,
                                                     genesisHash: genesisHash)
                    .adding(call: call)
                    .build(encodingBy: encoder.newEncoder(), metadata: metadata)

            let decoder = try DynamicScaleDecoder(data: extrinsicData,
                                                  registry: catalog,
                                                  version: UInt64(specVersion))

            let extrinsic: Extrinsic = try decoder.read(of: GenericType.extrinsic.name)

            let expectedCall = try call.toScaleCompatibleJSON()

            XCTAssertNil(extrinsic.signature)
            XCTAssertEqual(expectedCall, extrinsic.call)
            XCTAssertTrue(decoder.remained == 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUnknownSignedExtensionsNotIgnored() {
        let unsupportedExtension = "UnknownExtension"
        let genesisHash = Data(repeating: 0, count: 32).toHex(includePrefix: true)
        let specVersion: UInt32 = 28

        do {
            let account = Data(repeating: 1, count: 32)

            let args = TransferArgs(dest: .accoundId(account), value: 1)
            let call = RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)

            let closure: ExtrinsicBuilderClosure = { builder in
                return try builder.adding(call: call)
            }

            let prevMetadata = try RuntimeHelper.createRuntimeMetadata("polkadot-metadata")

            let newExtensions = prevMetadata.extrinsic.signedExtensions + [unsupportedExtension]
            let metadata = RuntimeMetadata(metaReserved: prevMetadata.metaReserved,
                                           runtimeMetadataVersion: prevMetadata.runtimeMetadataVersion,
                                           modules: prevMetadata.modules,
                                           extrinsic: ExtrinsicMetadata(version: prevMetadata.extrinsic.version,
                                                                        signedExtensions: newExtensions))

            try setupSignedExtrinsicBuilderTest("default",
                                                networkName: "polkadot",
                                                metadata: metadata,
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: nil)
        } catch {
            if
                let error = error as? ExtrinsicExtraNodeError,
                case .unsupportedExtension(let value) = error {
                XCTAssertEqual(unsupportedExtension, value)
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: Private

    private func setupSignedExtrinsicBuilderTest(_ baseName: String,
                                                 networkName: String,
                                                 metadataName: String,
                                                 genesisHash: String,
                                                 specVersion: UInt32,
                                                 builderClosure: ExtrinsicBuilderClosure,
                                                 expectedCall: JSON? = nil) throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata(metadataName)

        try setupSignedExtrinsicBuilderTest(baseName,
                                            networkName: networkName,
                                            metadata: metadata,
                                            genesisHash: genesisHash,
                                            specVersion: specVersion,
                                            builderClosure: builderClosure,
                                            expectedCall: expectedCall)
    }

    private func setupSignedExtrinsicBuilderTest(_ baseName: String,
                                                 networkName: String,
                                                 metadata: RuntimeMetadata,
                                                 genesisHash: String,
                                                 specVersion: UInt32,
                                                 builderClosure: ExtrinsicBuilderClosure,
                                                 expectedCall: JSON?) throws {
        // given

        let keypair = {
            try! SR25519KeypairFactory()
                .createKeypairFromSeed(Data(repeating: 8, count: 32), chaincodeList: [])
        }()

        let accountId = keypair.publicKey().rawData()

        let catalog = try RuntimeHelper
            .createTypeRegistryCatalog(from: baseName,
                                       networkName: networkName,
                                       runtimeMetadata: metadata)

        let privateKey = try SNPrivateKey(rawData: keypair.privateKey().rawData())
        let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())

        let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))

        let encoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

        let initialBuilder = try ExtrinsicBuilder(specVersion: specVersion,
                                                  transactionVersion: 4,
                                                  genesisHash: genesisHash)
            .with(address: MultiAddress.accoundId(accountId))

        let extrinsicData = try builderClosure(initialBuilder)
            .signing(by: { try signer.sign($0).rawData() },
                     of: .sr25519,
                     using: encoder.newEncoder(),
                     metadata: metadata)
            .build(encodingBy: encoder.newEncoder(), metadata: metadata)

        let decoder = try DynamicScaleDecoder(data: extrinsicData,
                                              registry: catalog,
                                              version: UInt64(specVersion))

        let extrinsic: Extrinsic = try decoder.read(of: GenericType.extrinsic.name)

        let expectedAddress = try MultiAddress.accoundId(accountId).toScaleCompatibleJSON()

        XCTAssertEqual(expectedAddress, extrinsic.signature?.address)

        if let expectedCall = expectedCall {
            XCTAssertEqual(expectedCall, extrinsic.call)
        }

        XCTAssertTrue(decoder.remained == 0)
    }
}
