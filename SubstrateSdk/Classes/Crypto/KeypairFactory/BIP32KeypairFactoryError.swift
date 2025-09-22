import NovaCrypto

public enum BIP32KeypairFactoryError: Error {
    case invalidMasterKey
    case invalidChildKey
    case unsupportedSoftDerivation
}
