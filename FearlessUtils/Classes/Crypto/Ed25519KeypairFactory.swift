import Foundation
import IrohaCrypto

public struct Ed25519KeypairFactory: KeypairFactoryProtocol {
    static let hdkdPrefix = "Ed25519HDKD"

    let internalFactory = EDKeyFactory()

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

        return try internalFactory.derive(fromSeed: childSeed)
    }
}
