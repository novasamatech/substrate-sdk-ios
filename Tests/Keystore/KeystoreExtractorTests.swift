import XCTest
import FearlessUtils
import IrohaCrypto

class KeystoreExtractorTests: XCTestCase {
    func testOnSr25519Json() {
        guard let url = Bundle(for: KeystoreExtractorTests.self)
            .url(forResource: "keystore-sr25519", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let keystore = try JSONDecoder().decode(KeystoreDefinition.self, from: testData)

            let extractor = KeystoreExtractor()

            let keystoreData = try extractor.extractFromDefinition(keystore,
                                                                   password: "test5")

            let privateKey = try SNPrivateKey(rawData: keystoreData.secretKeyData)
            let publicKey = try SNPublicKey(rawData: keystoreData.publicKeyData)

            let signer = SNSigner(keypair: SNKeypair(privateKey: privateKey, publicKey: publicKey))
            let signature = try signer.sign(privateKey.rawData())

            let verifier = SNSignatureVerifier()
            XCTAssertTrue(verifier.verify(signature, forOriginalData: privateKey.rawData(), using: publicKey))

            let addressFactory = SS58AddressFactory()
            let address = try addressFactory.address(
                fromAccountId: publicKey.rawData(),
                type: KnownChainType.kusamaMain.rawValue
            )

            XCTAssertEqual(address, keystoreData.address)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testOnEd25519Json() {
        guard let url = Bundle(for: KeystoreExtractorTests.self)
            .url(forResource: "keystore-ed25519", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let keystore = try JSONDecoder().decode(KeystoreDefinition.self, from: testData)

            let extractor = KeystoreExtractor()

            let keystoreData = try extractor.extractFromDefinition(keystore,
                                                                   password: "test2")

            let keypair = try Ed25519KeypairFactory().createKeypairFromSeed(keystoreData.secretKeyData[0..<32],
                                                                            chaincodeList: [])

            XCTAssertEqual(keypair.publicKey().rawData(), keystoreData.publicKeyData)

            let addressFactory = SS58AddressFactory()
            let address = try addressFactory.address(
                fromAccountId: keypair.publicKey().rawData(),
                type: KnownChainType.kusamaMain.rawValue
            )

            XCTAssertEqual(address, keystoreData.address)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testOnEcdsaJson() {
        guard let url = Bundle(for: KeystoreExtractorTests.self)
            .url(forResource: "keystore-ecdsa", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let keystore = try JSONDecoder().decode(KeystoreDefinition.self, from: testData)

            let extractor = KeystoreExtractor()

            let keystoreData = try extractor.extractFromDefinition(keystore,
                                                                   password: "test3")

            let keypair = try EcdsaKeypairFactory().createKeypairFromSeed(keystoreData.secretKeyData[0..<32],
                                                                          chaincodeList: [])

            XCTAssertEqual(keypair.publicKey().rawData(), keystoreData.publicKeyData)

            let addressFactory = SS58AddressFactory()
            let address = try addressFactory.address(
                fromAccountId: keypair.publicKey().rawData(),
                type: KnownChainType.kusamaMain.rawValue
            )

            XCTAssertEqual(address, keystoreData.address)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
