import Foundation
import IrohaCrypto

public struct SR25519KeypairFactory: KeypairFactoryProtocol {
    let internalFactory = SNKeyFactory()

    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let masterKeypair = try internalFactory.createKeypair(fromSeed: seed)

        let childKeypair = try chaincodeList.reduce(masterKeypair) { (keypair, chaincode) in
            switch chaincode.type {
            case .soft:
                return try internalFactory.createKeypairSoft(keypair, chaincode: chaincode.data)
            case .hard:
                return try internalFactory.createKeypairHard(keypair, chaincode: chaincode.data)
            }
        }

        return IRCryptoKeypair(publicKey: childKeypair.publicKey(),
                               privateKey: childKeypair.privateKey())
    }
}
