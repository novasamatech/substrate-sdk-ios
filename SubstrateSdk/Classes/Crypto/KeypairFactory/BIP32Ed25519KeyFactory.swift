import NovaCrypto
import BigInt

public final class BIP32Ed25519KeyFactory: BIP32KeypairFactory {
    private static let initialSeed = "ed25519 seed"
    let internalFactory = EDKeyFactory()
    
    public override init() {
        super.init()
    }
    
    override func deriveFromSeed(_ seed: Data) throws -> BIP32ExtendedKeypair {
        let hmacResult = try generateHMAC512(
            from: seed,
            secretKeyData: Data(Self.initialSeed.utf8)
        )

        let privateKeySeed = hmacResult[...31]
        let chainCode = hmacResult[32...]

        // we are returning seed as private key as both further derivation and signature requires it
        let publicKey = try internalFactory.derive(fromSeed: privateKeySeed).publicKey()
        let secretKey = try EDPrivateKey(rawData: privateKeySeed)
        
        let keypair = IRCryptoKeypair(publicKey: publicKey, privateKey: secretKey)

        return BIP32ExtendedKeypair(keypair: keypair, chaincode: chainCode)
    }

    override func createKeypairFrom(
        _ parentKeypair: BIP32ExtendedKeypair,
        chaincode: Chaincode
    ) throws -> BIP32ExtendedKeypair {
        let sourceData: Data = try {
            switch chaincode.type {
            case .hard:
                let padding = Data(repeating: 0, count: 1)
                let privateKeyData = parentKeypair.privateKey().rawData()

                return padding + privateKeyData + chaincode.data

            case .soft:
                throw BIP32KeypairFactoryError.unsupportedSoftDerivation
            }
        }()

        let hmacResult = try generateHMAC512(
            from: sourceData,
            secretKeyData: parentKeypair.chaincode
        )

        let childPrivateKeySeed = hmacResult[...31]
        let childChaincode = hmacResult[32...]
        
        // we are returning seed as private key as both further derivation and signature requires it
        let publicKey = try internalFactory.derive(fromSeed: childPrivateKeySeed).publicKey()
        let secretKey = try EDPrivateKey(rawData: childPrivateKeySeed)

        let keypair = IRCryptoKeypair(publicKey: publicKey, privateKey: secretKey)
        
        return BIP32ExtendedKeypair(keypair: keypair, chaincode: childChaincode)
    }
}
