import Foundation
import IrohaCrypto

public struct Ed25519KeypairFactory: KeypairFactoryProtocol {
    let internalFactory = EDKeyFactory()

    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let keypair = try internalFactory.derive(fromSeed: seed)

        guard !chaincodeList.isEmpty else {
            return keypair
        }

        let scaleEncoder = ScaleEncoder()
        try "Ed25519HDKD".encode(scaleEncoder: scaleEncoder)
        let prefix = scaleEncoder.encode()

        return try chaincodeList.reduce(keypair) { (keypair, chaincode) in
            guard chaincode.type == .hard else {
                throw KeypairFactoryError.unsupportedChaincodeType
            }

            let childSeed = try (prefix + keypair.privateKey().rawData() + chaincode.data).blake2b32()

            return try internalFactory.derive(fromSeed: childSeed)
        }
    }
}
