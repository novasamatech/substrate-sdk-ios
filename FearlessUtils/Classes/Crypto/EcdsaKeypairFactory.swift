import Foundation
import IrohaCrypto

public struct EcdsaKeypairFactory: KeypairFactoryProtocol {
    static let hdkdPrefix = "Secp256k1HDKD"

    let internalFactory = SECKeyFactory()

    public init() {}

    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let scaleEncoder = ScaleEncoder()
        try Self.hdkdPrefix.encode(scaleEncoder: scaleEncoder)
        let prefix = scaleEncoder.encode()

        let childSeed = try chaincodeList.reduce(seed) { (currentSeed, chaincode) in
            guard chaincode.type == .hard else {
                throw KeypairFactoryError.unsupportedChaincodeType
            }

            return try (prefix + currentSeed + chaincode.data).blake2b32()
        }

        let childPrivateKey = try SECPrivateKey(rawData: childSeed)
        return try internalFactory.derive(fromPrivateKey: childPrivateKey)
    }
}
