import NovaCrypto

public enum BIP32KeypairFactoryError: Error {
    case invalidChildKey
    case unsupportedSoftDerivation
}
