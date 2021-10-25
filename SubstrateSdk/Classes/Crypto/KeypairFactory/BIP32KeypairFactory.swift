import Foundation
import IrohaCrypto

public struct BIP32KeypairFactory {
    let internalFactory = BIP32KeyFactory()

    public init() {}

    private func deriveChildKeypairFromMaster(
        _ masterKeypair: BIP32ExtendedKeypair,
        chainIndexList: [Chaincode]
    ) throws -> IRCryptoKeypairProtocol {
        let childExtendedKeypair = try chainIndexList.reduce(masterKeypair) { (parentKeypair, chainIndex) in
            try internalFactory.createKeypairFrom(parentKeypair, chaincode: chainIndex)
        }

        return childExtendedKeypair.keypair
    }
}

extension BIP32KeypairFactory: KeypairFactoryProtocol {
    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let masterKeypair = try internalFactory.deriveFromSeed(seed)

        return try deriveChildKeypairFromMaster(
            masterKeypair,
            chainIndexList: chaincodeList
        )
    }
}
