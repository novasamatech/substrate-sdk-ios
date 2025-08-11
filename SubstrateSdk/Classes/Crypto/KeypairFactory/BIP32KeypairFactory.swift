import CommonCrypto
import NovaCrypto

public class BIP32KeypairFactory {
    func deriveFromSeed(_ seed: Data) throws -> BIP32ExtendedKeypair {
        fatalError("Must be overriden by subsclass")
    }
    
    func createKeypairFrom(_ parentKeypair: BIP32ExtendedKeypair, chaincode: Chaincode) throws -> BIP32ExtendedKeypair {
        fatalError("Must be overriden by subsclass")
    }
    
    func generateHMAC512(
        from originalData: Data,
        secretKeyData: Data
    ) throws -> Data {
        let digestLength = Int(CC_SHA512_DIGEST_LENGTH)
        let algorithm = CCHmacAlgorithm(kCCHmacAlgSHA512)

        var buffer = [UInt8](repeating: 0, count: digestLength)

        originalData.withUnsafeBytes {
            let rawOriginalDataPtr = $0.baseAddress!

            secretKeyData.withUnsafeBytes {
                let rawSecretKeyPtr = $0.baseAddress!

                CCHmac(
                    algorithm,
                    rawSecretKeyPtr,
                    secretKeyData.count,
                    rawOriginalDataPtr,
                    originalData.count,
                    &buffer
                )
            }
        }

        return Data(bytes: buffer, count: digestLength)
    }
}

private extension BIP32KeypairFactory {
    func deriveChildKeypairFromMaster(
        _ masterKeypair: BIP32ExtendedKeypair,
        chainIndexList: [Chaincode]
    ) throws -> IRCryptoKeypairProtocol {
        let childExtendedKeypair = try chainIndexList.reduce(masterKeypair) { parentKeypair, chainIndex in
            try createKeypairFrom(parentKeypair, chaincode: chainIndex)
        }

        return childExtendedKeypair.keypair
    }
}

extension BIP32KeypairFactory: KeypairFactoryProtocol {
    public func createKeypairFromSeed(
        _ seed: Data,
        chaincodeList: [Chaincode]
    ) throws -> IRCryptoKeypairProtocol {
        let masterKeypair = try deriveFromSeed(seed)

        return try deriveChildKeypairFromMaster(
            masterKeypair,
            chainIndexList: chaincodeList
        )
    }
}
