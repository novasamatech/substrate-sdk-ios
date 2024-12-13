import XCTest
import SubstrateSdk
import IrohaCrypto

final class ExtrinsicBuilderV5Tests: XCTestCase {
    func testV5ExtrinsicGenerateEncodeDecode() throws {
        let data = Data(repeating: 8, count: 32)
        let keypair = try SR25519KeypairFactory().createKeypairFromSeed(data, chaincodeList: [])

        let metadata = try PostV14RuntimeHelper.createMetadata(for: "westend-v15-metadata", isOpaque: true)
        
        let augmentationFactory = RuntimeAugmentationFactory()
        let result = augmentationFactory.createSubstrateAugmentation(for: metadata)
        
        let catalog = try TypeRegistryCatalog.createFromSiDefinition(
            runtimeMetadata: metadata,
            additionalNodes: result.additionalNodes.nodes
        )
        
        let encoder = DynamicScaleEncoder(registry: catalog, version: 0)
        let encodingFactory = WrappedDynamicScaleEncoderFactory(encoder: encoder)

        let call = RuntimeCall(
            moduleName: "Balances",
            callName: "transfer_allow_death",
            args: TransferArgs(dest: .accoundId(keypair.publicKey().rawData()), value: 10_000_000_000)
        )
        
        let extrinsicData = try ExtrinsicBuilder(
            extrinsicVersion: .V5(extensionVersion: 0),
            specVersion: 1017000,
            transactionVersion: 27,
            genesisHash: "e143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e"
        )
            .with(era: .immortal, blockHash: "e143f23803ac50e8f6f8e62695d1ce9e4e1d68aa36c1cd2cfd15340213f3423e")
            .with(nonce: 1)
            .with(address: MultiAddress.accoundId(keypair.publicKey().rawData()))
            .adding(call: call)
            .signing(
                by: { payload in
                    let privateKey = try SNPrivateKey(rawData: keypair.privateKey().rawData())
                    let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())
                    let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))
                    return try signer.sign(payload).rawData()
                },
                of: .sr25519,
                using: encodingFactory,
                metadata: metadata
            ).build(
                using: encodingFactory,
                metadata: metadata
            )
        
        let decoder = try DynamicScaleDecoder(
            data: extrinsicData,
            registry: catalog,
            version: 0
        )
        
        let _: Extrinsic = try decoder.read(of: GenericType.extrinsic.name)
    }
}
