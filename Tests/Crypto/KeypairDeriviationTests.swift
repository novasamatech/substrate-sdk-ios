import XCTest
import FearlessUtils
import IrohaCrypto

class KeypairDeriviationTests: XCTestCase {

    func testSr25519FromTestVectors() throws {
        try performTest(filename: "sr25519HDKD", keypairFactory: SR25519KeypairFactory())
    }

    func testEd25519DerivationPath() throws {
        try performTest(filename: "ed25519HDKD", keypairFactory: Ed25519KeypairFactory())
    }

    func testEcdsaDerivationPath() throws {
        try performTest(filename: "ecdsaHDKD", keypairFactory: EcdsaKeypairFactory())
    }

    private func performTest(filename: String, keypairFactory: KeypairFactoryProtocol) throws {
        guard let url = Bundle(for: KeypairDeriviationTests.self)
                .url(forResource: filename, withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([KeypairDeriviation].self, from: testData)

            let junctionFactory = SubstrateJunctionFactory()
            let seedFactory = SeedFactory()

            for item in items {
                let result: JunctionResult

                if !item.path.isEmpty {
                    result = try junctionFactory.parse(path: item.path)
                } else {
                    result = JunctionResult(chaincodes: [], password: nil)
                }

                let seedResult = try seedFactory.deriveSeed(from: item.mnemonic,
                                                            password: result.password ?? "")

                let keypair = try keypairFactory.createKeypairFromSeed(
                    seedResult.seed.miniSeed,
                    chaincodeList: result.chaincodes
                )

                let publicKey = keypair.publicKey().rawData()

                let expectedPublicKey = try Data(hexString: item.publicKey)

                if publicKey != expectedPublicKey {
                    XCTFail("Failed for path: \(item.path)")
                }
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
