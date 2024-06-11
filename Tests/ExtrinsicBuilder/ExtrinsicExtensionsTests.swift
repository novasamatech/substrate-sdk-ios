import XCTest
import SubstrateSdk
import IrohaCrypto
import BigInt

class ExtrinsicExtensionsTests: XCTestCase {
    func testChargeAssetExtension() throws {
        let expected = "0x45028400fdc41550fb5186d71cae699c31731b3e1baa10680c7bd6b3831a6d222cf4d1680045ba1f9d291fff7dddf36f7ec060405d5e87ac8fab8832cfcc66858e6975141748ce89c41bda6c3a84204d3c6f929b928702168ca38bbed69b172044b599a10ab5038800000a0000bcc5ecf679ebd776866a04c212a4ec5dc45cefab57d7aa858c389844e212693f0700e40b5402"

        let extrinsicExtension = ExtrinsicSignedExtension.ChargeAssetTxPayment()
        let extensionCoder = DefaultExtrinsicSignedExtensionCoder(
            signedExtensionId: extrinsicExtension.signedExtensionId,
            extraType: "pallet_asset_tx_payment.ChargeAssetTxPayment"
        )

        let catalog = try ScaleInfoHelper.createTypeRegistry(
            from: "statemine-v14-metadata",
            networkFilename: "statemine",
            customExtensions: [extensionCoder]
        )

        let metadata = try ScaleInfoHelper.createScaleInfoMetadata(for: "statemine-v14-metadata")

        let specVersion: UInt32 = 601

        let decoder = try DynamicScaleDecoder(
            data: try! Data(hexString: expected),
            registry: catalog,
            version: UInt64(specVersion)
        )

        let extrinsic = try decoder.read(type: GenericType.extrinsic.name).map(to: Extrinsic.self, with: nil)

        let era = extrinsic.signature!.extra.getEra()!
        
        let nonce = extrinsic.signature!.extra.getNonce()!
        
        var builder = try ExtrinsicBuilder(
            specVersion: specVersion,
            transactionVersion: 4,
            genesisHash: "48239ef607d7928874027a43a67689209727dfb3d3dc5e5b03a39bdc2eda771a"
        )
            .with(
                era: era,
                blockHash: "dd7532c5c01242696001e57cded1bc1326379059300287552a9c344e5bea1070"
        )
            .with(address: extrinsic.signature!.address)
            .with(nonce: nonce)

        let recepientAccountId = try SS58AddressFactory().accountId(
            fromAddress: "GqqKJJZ1MtiWiC6CzNg3g8bawriq6HZioHW1NEpxdf6Q6P5",
            type: 2
        )

        let amount = BigUInt(10000000000)

        let call = RuntimeCall(
            moduleName: "Balances",
            callName: "transfer",
            args: TransferArgs(dest: .accoundId(recepientAccountId), value: amount)
        )

        builder = try builder.adding(call: call)
        builder = builder.adding(extrinsicSignedExtension: extrinsicExtension)

        let signatureEncoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

        builder = try builder.signing(
            by: { _ in extrinsic.signature!.signature },
            using: signatureEncoder,
            metadata: metadata
        )

        let builderEncoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

        let actual = try builder
            .build(encodingBy: builderEncoder, metadata: metadata).toHex(includePrefix: true)

        XCTAssertEqual(actual, expected)
    }
}
