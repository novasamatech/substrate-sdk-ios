import XCTest
@testable import SubstrateSdk
import NovaCrypto
#if canImport(TestHelpers)
import TestHelpers
#endif

final class BIP32Ed25519KeypairDerivationTests: XCTestCase {
    struct TestVectorItem: Decodable {
        let seed: String
        let derivationPath: String?
        let privateKey: String
        let publicKey: String
        
        func getPublicKeyWithoutPrefix() throws -> Data {
            // drop "00" prefix which is present in slip10 vectors
            // It is present in the test vectors ensure unified format with other vectors
            // But we do not need it
            try Data(hexString: publicKey).dropFirst(1)
        }
    }
    
    func testSoftDerivationNotSupported() throws {
        let factory = BIP32Ed25519KeyFactory()
        
        let junction = try BIP32JunctionFactory().parse(path: "/0")
        
        let seed = try Data(hexString: "000102030405060708090a0b0c0d0e0f")
        
        XCTAssertThrowsError(
            try factory.createKeypairFromSeed(seed, chaincodeList: junction.chaincodes),
            "Error is expected"
        ) { error in
            guard let bip32Error = error as? BIP32KeypairFactoryError else {
                XCTFail("Keypair derivation error is expected")
                return
            }
            
            XCTAssert(bip32Error == .unsupportedSoftDerivation)
        }
    }
    
    // SLIP-0010 Official Test Vectors: https://github.com/satoshilabs/slips/blob/master/slip-0010.md
    func testDerivationFromSeed() throws {
        try performTest(filename: "BIP32Ed25519HDKDEtalon", keypairFactory: BIP32Ed25519KeyFactory())
    }
    
    private func performTest(filename: String, keypairFactory: KeypairFactoryProtocol) throws {
        let bundle: Bundle
#if SWIFT_PACKAGE
        bundle = Bundle.module
#else
        bundle = Bundle(for: KeypairDeriviationTests.self)
#endif
        guard let url = bundle
            .url(forResource: filename, withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let items = try decoder.decode([TestVectorItem].self, from: testData)

            let junctionFactory = BIP32JunctionFactory()

            for item in items {
                let result: JunctionResult

                if let derivationPath = item.derivationPath, !derivationPath.isEmpty {
                    result = try junctionFactory.parse(path: derivationPath)
                } else {
                    result = JunctionResult(chaincodes: [], password: nil)
                }
                
                let seed = try Data(hexString: item.seed)

                let keypair = try keypairFactory.createKeypairFromSeed(seed, chaincodeList: result.chaincodes)

                let expectedPublicKey = try item.getPublicKeyWithoutPrefix()

                let actualPublicKey = keypair.publicKey().rawData()
                
                XCTAssertEqual(
                    expectedPublicKey,
                    actualPublicKey,
                    "Expected public key \(expectedPublicKey.toHex()) but received \(actualPublicKey.toHex())"
                )
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

}
