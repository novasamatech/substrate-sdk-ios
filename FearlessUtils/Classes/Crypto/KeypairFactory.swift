import Foundation
import IrohaCrypto

enum KeypairFactoryError: Error {
    case unsupportedChaincodeType
}

public protocol KeypairFactoryProtocol {
    func createKeypairFromSeed(_ seed: Data, chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol
}
