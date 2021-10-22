import XCTest
import FearlessUtils
import IrohaCrypto

class SeedFactoryTests: XCTestCase {
    func testGeneratedSeedMatchesDerived() throws {
        let seedFactory = SeedFactory()
        try performSeedFactoryTest(seedFactory)
    }

    func testGeneratedBIP32SeedMatchesDerived() throws {
        let seedFactory = BIP32SeedFactory()
        try performSeedFactoryTest(seedFactory)
    }

    func performSeedFactoryTest(_ seedFactory: SeedFactoryProtocol) throws {
        let passwords: [String] = ["", "password"]
        let strengths: [IRMnemonicStrength] = [
            .entropy128,
            .entropy160,
            .entropy192,
            .entropy224,
            .entropy256,
            .entropy288,
            .entropy320
        ]

        for password in passwords {
            for strength in strengths {
                let expectedResult = try seedFactory.createSeed(from: password, strength: strength)
                let derivedResult = try seedFactory.deriveSeed(from: expectedResult.mnemonic.toString(),
                                                               password: password)

                XCTAssertEqual(expectedResult.seed, derivedResult.seed)
            }
        }
    }
}
