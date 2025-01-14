import XCTest
import SubstrateSdk
import NovaCrypto
import BigInt

typealias ExtrinsicBuilderClosure = (ExtrinsicBuilderProtocol) throws -> ExtrinsicBuilderProtocol

class ExtrinsicBuilderTests: XCTestCase {
    func testExtrinsicWithBatchCall() {
        let genesisHash = Data(repeating: 0, count: 32).toHex(includePrefix: true)
        let specVersion: UInt32 = 48

        do {

            let calls: [RuntimeCall<TransferArgs>] = (0..<10).map { index in
                let account = Data(repeating: UInt8(index % 256), count: 32)

                let args = TransferArgs(dest: .accoundId(account), value: BigUInt(index) + 1)
                return RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)
            }

            let closure: ExtrinsicBuilderClosure = { builder in
                return try calls.reduce(builder.with(shouldUseAtomicBatch: false)) { try $0.adding(call: $1) }
            }

            let expectedJsonCalls = try calls.toScaleCompatibleJSON()
            let expectedCall = try RuntimeCall(moduleName: KnowRuntimeModule.Utility.name,
                                               callName: KnowRuntimeModule.Utility.batch,
                                               args: BatchArgs(calls: expectedJsonCalls.arrayValue!))
                                .toScaleCompatibleJSON()

            try setupSignedExtrinsicBuilderTest("default",
                                                networkName: "westend",
                                                metadataName: "westend-metadata",
                                                cryptoType: .sr25519,
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: expectedCall)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExtrinsicWithBatchAllCall() {
        let genesisHash = Data(repeating: 0, count: 32).toHex(includePrefix: true)
        let specVersion: UInt32 = 48

        do {

            let calls: [RuntimeCall<TransferArgs>] = (0..<10).map { index in
                let account = Data(repeating: UInt8(index % 256), count: 32)

                let args = TransferArgs(dest: .accoundId(account), value: BigUInt(index) + 1)
                return RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)
            }

            let closure: ExtrinsicBuilderClosure = { builder in
                return try calls.reduce(builder) { try $0.adding(call: $1) }
            }

            let expectedJsonCalls = try calls.toScaleCompatibleJSON()
            let expectedCall = try RuntimeCall(moduleName: KnowRuntimeModule.Utility.name,
                                               callName: KnowRuntimeModule.Utility.batchAll,
                                               args: BatchArgs(calls: expectedJsonCalls.arrayValue!))
                                .toScaleCompatibleJSON()

            try setupSignedExtrinsicBuilderTest("default",
                                                networkName: "westend",
                                                metadataName: "westend-metadata",
                                                cryptoType: .sr25519,
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: expectedCall)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExtrinsicWithRawCall() {
        let genesisHash = Data(repeating: 0, count: 32).toHex(includePrefix: true)
        let specVersion: UInt32 = 48

        do {

            let catalog = try RuntimeHelper.createTypeRegistryCatalog(
                from: "default",
                networkName: "westend",
                runtimeMetadataName: "westend-metadata"
            )

            let encoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

            let accountId = Data(repeating: 0, count: 32)
            let args = TransferArgs(dest: .accoundId(accountId), value: 1)
            let call = RuntimeCall(moduleName: "Balances",
                                   callName: "transfer",
                                   args: args)

            try encoder.append(json: call.toScaleCompatibleJSON(), type: KnownType.call.name)
            let encodedCall = try encoder.encode()

            let closure: ExtrinsicBuilderClosure = { builder in
                return try builder.adding(rawCall: encodedCall)
            }

            let expectedCall = try call.toScaleCompatibleJSON()

            try setupSignedExtrinsicBuilderTest("default",
                                                networkName: "westend",
                                                metadataName: "westend-metadata",
                                                cryptoType: .sr25519,
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: expectedCall)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSingleCallWithSR25519() {
        performExtrinsicWithSingleCall(for: .sr25519)
    }

    func testSingleCallWithED25519() {
        performExtrinsicWithSingleCall(for: .ed25519)
    }

    func testSingleCallWithEcdsa() {
        performExtrinsicWithSingleCall(for: .ecdsa)
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

    func testSignatureBuilder() {
        let cryptoTypes: [CryptoType] = [.sr25519, .ed25519, .ecdsa]

        for cryptoType in cryptoTypes {
            performExtrinsicSignatureWithSingleCall(for: cryptoType)
        }
    }

    // MARK: Private

    private func performExtrinsicWithSingleCall(for cryptoType: CryptoType) {
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
                                                cryptoType: cryptoType,
                                                genesisHash: genesisHash,
                                                specVersion: specVersion,
                                                builderClosure: closure,
                                                expectedCall: expectedCall)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func performExtrinsicSignatureWithSingleCall(for cryptoType: CryptoType) {
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

            let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

            try setupSignatureBuilderTest("default",
                                          networkName: "westend",
                                          metadata: metadata,
                                          cryptoType: cryptoType,
                                          genesisHash: genesisHash,
                                          specVersion: specVersion,
                                          builderClosure: closure)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func setupSignedExtrinsicBuilderTest(_ baseName: String,
                                                 networkName: String,
                                                 metadataName: String,
                                                 cryptoType: CryptoType,
                                                 genesisHash: String,
                                                 specVersion: UInt32,
                                                 builderClosure: ExtrinsicBuilderClosure,
                                                 expectedCall: JSON? = nil) throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata(metadataName)

        try setupSignedExtrinsicBuilderTest(baseName,
                                            networkName: networkName,
                                            metadata: metadata,
                                            cryptoType: cryptoType,
                                            genesisHash: genesisHash,
                                            specVersion: specVersion,
                                            builderClosure: builderClosure,
                                            expectedCall: expectedCall)
    }

    private func setupSignedExtrinsicBuilderTest(_ baseName: String,
                                                 networkName: String,
                                                 metadata: RuntimeMetadata,
                                                 cryptoType: CryptoType,
                                                 genesisHash: String,
                                                 specVersion: UInt32,
                                                 builderClosure: ExtrinsicBuilderClosure,
                                                 expectedCall: JSON?) throws {
        // given

        let keypair: IRCryptoKeypairProtocol = {
            let data = Data(repeating: 8, count: 32)
            switch cryptoType {
            case .sr25519:
                return try! SR25519KeypairFactory().createKeypairFromSeed(data, chaincodeList: [])
            case .ed25519:
                return try! Ed25519KeypairFactory().createKeypairFromSeed(data, chaincodeList: [])
            case .ecdsa:
                return try! EcdsaKeypairFactory().createKeypairFromSeed(data, chaincodeList: [])
            }
        }()

        let accountId = try keypair.publicKey().rawData().publicKeyToAccountId()

        let catalog = try RuntimeHelper
            .createTypeRegistryCatalog(from: baseName,
                                       networkName: networkName,
                                       runtimeMetadata: metadata)

        let signingClosure: (Data) throws -> Data = { message in
            XCTAssert(message.count <= 256)

            switch cryptoType {
            case .sr25519:
                let privateKey = try SNPrivateKey(rawData: keypair.privateKey().rawData())
                let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())
                let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))
                return try signer.sign(message).rawData()
            case .ed25519:
                let signer = EDSigner(privateKey: keypair.privateKey())
                return try signer.sign(message).rawData()
            case .ecdsa:
                let signer = SECSigner(privateKey: keypair.privateKey())
                let hashed = try message.blake2b32()
                return try signer.sign(hashed).rawData()
            }
        }

        let encoder = DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion))

        let initialBuilder = try ExtrinsicBuilder(specVersion: specVersion,
                                                  transactionVersion: 4,
                                                  genesisHash: genesisHash)
            .with(address: MultiAddress.accoundId(accountId))

        let extrinsicData = try builderClosure(initialBuilder)
            .signing(by: signingClosure,
                     of: cryptoType,
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

    private func setupSignatureBuilderTest(_ baseName: String,
                                           networkName: String,
                                           metadata: RuntimeMetadata,
                                           cryptoType: CryptoType,
                                           genesisHash: String,
                                           specVersion: UInt32,
                                           builderClosure: ExtrinsicBuilderClosure) throws {
        let keypair: IRCryptoKeypairProtocol = {
            let data = Data(repeating: 8, count: 32)
            switch cryptoType {
            case .sr25519:
                return try! SR25519KeypairFactory().createKeypairFromSeed(data, chaincodeList: [])
            case .ed25519:
                return try! Ed25519KeypairFactory().createKeypairFromSeed(data, chaincodeList: [])
            case .ecdsa:
                return try! EcdsaKeypairFactory().createKeypairFromSeed(data, chaincodeList: [])
            }
        }()

        let accountId = try keypair.publicKey().rawData().publicKeyToAccountId()

        let catalog = try RuntimeHelper
            .createTypeRegistryCatalog(from: baseName,
                                       networkName: networkName,
                                       runtimeMetadata: metadata)

        let signingClosure: (Data) throws -> Data = { message in
            XCTAssert(message.count <= 256)

            switch cryptoType {
            case .sr25519:
                let privateKey = try SNPrivateKey(rawData: keypair.privateKey().rawData())
                let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())
                let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))
                return try signer.sign(message).rawData()
            case .ed25519:
                let signer = EDSigner(privateKey: keypair.privateKey())
                return try signer.sign(message).rawData()
            case .ecdsa:
                let signer = SECSigner(privateKey: keypair.privateKey())
                let hashed = try message.blake2b32()
                return try signer.sign(hashed).rawData()
            }
        }

        let verificationClosure: (Data, Data) throws -> Bool = { message, rawSignature in
            switch cryptoType {
            case .sr25519:
                let publicKey = try SNPublicKey(rawData: keypair.publicKey().rawData())
                let verifier = SNSignatureVerifier()
                let signature = try SNSignature(rawData: rawSignature)
                return verifier.verify(signature, forOriginalData: message, using: publicKey)
            case .ed25519:
                let publicKey = try EDPublicKey(rawData: keypair.publicKey().rawData())
                let verifier = EDSignatureVerifier()
                let signature = try EDSignature(rawData: rawSignature)
                return verifier.verify(signature, forOriginalData: message, usingPublicKey: publicKey)
            case .ecdsa:
                let publicKey = try SECPublicKey(rawData: keypair.publicKey().rawData())
                let verifier = SECSignatureVerifier()
                let signature = try SECSignature(rawData: rawSignature)
                let hashed = try message.blake2b32()
                return verifier.verify(signature, forOriginalData: hashed, usingPublicKey: publicKey)
            }
        }

        let initialBuilder = try ExtrinsicBuilder(specVersion: specVersion,
                                                  transactionVersion: 4,
                                                  genesisHash: genesisHash)
            .with(address: MultiAddress.accoundId(accountId))

        let processedBuilder = try builderClosure(initialBuilder)

        let originalData = try processedBuilder.buildSignaturePayload(
            encoder: DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion)),
            metadata: metadata
        )

        let rawSignature = try processedBuilder.buildRawSignature(
            using: signingClosure,
            encoder: DynamicScaleEncoder(registry: catalog, version: UInt64(specVersion)),
            metadata: metadata
        )

        let result = try verificationClosure(originalData, rawSignature)

        XCTAssertTrue(result)
    }
}
