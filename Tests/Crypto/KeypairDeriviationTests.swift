import XCTest
import FearlessUtils

class KeypairDeriviationTests: XCTestCase {

    func testSr25519FromTestVectors() throws {
        guard let url = Bundle(for: KeypairDeriviationTests.self)
            .url(forResource: "sr25519HDKD", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([KeypairDeriviation].self, from: testData)

            let factory = SR25519KeypairFactory()
            let junctionFactory = JunctionFactory()
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
                let keypair = try factory.createKeypairFromSeed(seedResult.seed,
                                                                chaincodeList: result.chaincodes)

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
