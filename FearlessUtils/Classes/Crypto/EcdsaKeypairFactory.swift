import Foundation
import IrohaCrypto

public struct EcdsaKeypairFactory: KeypairFactoryProtocol {
    let internalFactory = SECKeyFactory()

    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let privateKey = try SECPrivateKey(rawData: seed)
        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        guard !chaincodeList.isEmpty else {
            return keypair
        }

        let scaleEncoder = ScaleEncoder()
        try "Secp256k1HDKD".encode(scaleEncoder: scaleEncoder)
        let prefix = scaleEncoder.encode()

        return try chaincodeList.reduce(keypair) { (keypair, chaincode) in
            guard chaincode.type == .hard else {
                throw KeypairFactoryError.unsupportedChaincodeType
            }

            let childSeed = try (prefix + keypair.privateKey().rawData() + chaincode.data).blake2b32()

            let childPrivateKey = try SECPrivateKey(rawData: childSeed)
            return try internalFactory.derive(fromPrivateKey: childPrivateKey)
        }
    }
}
