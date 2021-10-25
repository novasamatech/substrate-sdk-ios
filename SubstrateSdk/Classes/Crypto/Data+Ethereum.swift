import Foundation
import keccak
import IrohaCrypto

public enum EthereumPubKeyToAddressError: Error {
    case invalidPublicKey
    case invalidPrefix
}

public extension Data {
    func ethereumAddressFromPublicKey() throws -> Data {
        let uncompressedKey: Data

        if count == SECPublicKey.uncompressedLength() {
            uncompressedKey = self
        } else if count == SECPublicKey.length() {
            let compressedPublicKey = try SECPublicKey(rawData: self)
            uncompressedKey = try compressedPublicKey.uncompressed()
        } else {
            throw EthereumPubKeyToAddressError.invalidPublicKey
        }

        guard uncompressedKey[0] == 0x04 else {
            throw EthereumPubKeyToAddressError.invalidPrefix
        }

        return try uncompressedKey.dropFirst().keccak256().suffix(20)
    }
}
