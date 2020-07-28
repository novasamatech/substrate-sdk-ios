import XCTest
import FearlessUtils

class KeypairDeriviationTests: XCTestCase {

    func testSr25519FromTestVectors() throws {
        let factory = SR25519KeypairFactory()
        let junctionFactory = JunctionFactory()
        let seedFactory = SeedFactory()

        for item in sr25519Deriviation {
            do {
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

                if publicKey != item.publicKey {
                    XCTFail("Failed for path: \(item.path)")
                }
            } catch {
                XCTFail("Unexpected error for path \(item.path) \(error)")
            }
        }
    }
}
