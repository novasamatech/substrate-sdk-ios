import XCTest
import FearlessUtils
import IrohaCrypto

class ExtrinsicBuilderTests: XCTestCase {
    func testBatchBuilder() throws {
        do {
            // given
            let genesisHash = "0xe143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e"
            let specVersion: UInt32 = 48

            let keypair = {
                try! SR25519KeypairFactory()
                    .createKeypairFromSeed(Data(repeating: 7, count: 32), chaincodeList: [])
            }()

            let accountId = keypair.publicKey().rawData()

            let catalog = try RuntimeHelper
                .createTypeRegistryCatalog(from: "default",
                                           networkName: "westend",
                                           runtimeMetadataName: "westend-metadata")
            let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

            let privateKey = try SNPrivateKey(rawData: keypair.privateKey().rawData())
            let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())

            let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))

            let encoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

            let args = TransferArgs(dest: .accoundId(accountId), value: 1)
            let call = RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)

            let extrinsicData = try ExtrinsicBuilder(specVersion: specVersion,
                                                     transactionVersion: 4,
                                                     genesisHash: genesisHash)
                    .with(address: MultiAddress.accoundId(accountId))
                    .adding(call: call)
                    .adding(call: call)
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

            let expectedJsonCalls = try [call, call].toScaleCompatibleJSON()
            let expectedCall = try RuntimeCall(moduleName: KnowRuntimeModule.Utitlity.name,
                                               callName: KnowRuntimeModule.Utitlity.batch,
                                               args: BatchArgs(calls: expectedJsonCalls.arrayValue!))
                                .toScaleCompatibleJSON()

            XCTAssertEqual(expectedAddress, extrinsic.signature?.address)
            XCTAssertEqual(expectedCall, extrinsic.call)
            XCTAssertTrue(decoder.remained == 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSingleExtrinsicBuilder() {
        do {
            // given
            let genesisHash = "0xe143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e"
            let specVersion: UInt32 = 48

            let keypair = {
                try! SR25519KeypairFactory()
                    .createKeypairFromSeed(Data(repeating: 8, count: 32), chaincodeList: [])
            }()

            let accountId = keypair.publicKey().rawData()

            let catalog = try RuntimeHelper
                .createTypeRegistryCatalog(from: "default",
                                           networkName: "westend",
                                           runtimeMetadataName: "westend-metadata")
            let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

            let privateKey = try SNPrivateKey(rawData: keypair.privateKey().rawData())
            let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())

            let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))

            let encoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

            let args = TransferArgs(dest: .accoundId(accountId), value: 1)
            let call = RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)

            let extrinsicData = try ExtrinsicBuilder(specVersion: specVersion,
                                                     transactionVersion: 4,
                                                     genesisHash: genesisHash)
                    .with(address: MultiAddress.accoundId(accountId))
                    .adding(call: call)
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

            let expectedCall = try call.toScaleCompatibleJSON()

            XCTAssertEqual(expectedAddress, extrinsic.signature?.address)
            XCTAssertEqual(expectedCall, extrinsic.call)
            XCTAssertTrue(decoder.remained == 0)
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
}
