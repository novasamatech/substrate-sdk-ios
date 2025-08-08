import NovaCrypto
import BigInt

public final class BIP32Secp256KeypairFactory: BIP32KeypairFactory {
    private static let initialSeed = "Bitcoin seed"
    let internalFactory = SECKeyFactory()
    
    public override init() {
        super.init()
    }
    
    override func deriveFromSeed(_ seed: Data) throws -> BIP32ExtendedKeypair {
        let hmacResult = try generateHMAC512(
            from: seed,
            secretKeyData: Data(Self.initialSeed.utf8)
        )

        let privateKeyData = hmacResult[...31]
        let privateKey = try SECPrivateKey(rawData: privateKeyData)
        let chainCode = hmacResult[32...]

        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        return BIP32ExtendedKeypair(
            keypair: keypair,
            nextSeed: privateKeyData,
            chaincode: chainCode
        )
    }

    override func createKeypairFrom(
        _ parentKeypair: BIP32ExtendedKeypair,
        chaincode: Chaincode
    ) throws -> BIP32ExtendedKeypair {
        let sourceData: Data = {
            switch chaincode.type {
            case .hard:
                let padding = Data(repeating: 0, count: 1)

                return padding + parentKeypair.nextSeed + chaincode.data

            case .soft:
                return parentKeypair.publicKey().rawData() + chaincode.data
            }
        }()

        let hmacResult = try generateHMAC512(
            from: sourceData,
            secretKeyData: parentKeypair.chaincode
        )

        let privateKeySourceData = try SECPrivateKey(rawData: hmacResult[...31])
        let childChaincode = hmacResult[32...]

        var privateKeyInt = BigUInt(privateKeySourceData.rawData())

        guard privateKeyInt < .secp256k1CurveOrder else {
            throw BIP32KeypairFactoryError.invalidChildKey
        }

        privateKeyInt += BigUInt(parentKeypair.nextSeed)
        privateKeyInt %= .secp256k1CurveOrder

        guard privateKeyInt > 0 else {
            throw BIP32KeypairFactoryError.invalidChildKey
        }

        var privateKeyData = privateKeyInt.serialize()

        let keyLength = SECPrivateKey.length()

        if privateKeyData.count < keyLength {
            let padding = Data(
                repeating: 0,
                count: Int(keyLength) - privateKeyData.count
            )
            privateKeyData = padding + privateKeyData
        }

        let privateKey = try SECPrivateKey(rawData: privateKeyData)
        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        return BIP32ExtendedKeypair(
            keypair: keypair,
            nextSeed: privateKeyData,
            chaincode: childChaincode
        )
    }
}
