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

        let keypair = try internalFactory.derive(fromSeed: privateKeySeed)

        return BIP32ExtendedKeypair(
            keypair: keypair,
            nextSeed: privateKeySeed,
            chaincode: chainCode
        )
    }

    override func createKeypairFrom(
        _ parentKeypair: BIP32ExtendedKeypair,
        chaincode: Chaincode
    ) throws -> BIP32ExtendedKeypair {
        let sourceData: Data = try {
            switch chaincode.type {
            case .hard:
                let padding = Data(repeating: 0, count: 1)

                return padding + parentKeypair.nextSeed + chaincode.data

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
        let keypair = try internalFactory.derive(fromSeed: childPrivateKeySeed)

        return BIP32ExtendedKeypair(
            keypair: keypair,
            nextSeed: childPrivateKeySeed,
            chaincode: childChaincode
        )
    }
}
