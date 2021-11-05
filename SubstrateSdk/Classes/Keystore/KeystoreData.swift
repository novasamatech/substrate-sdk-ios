import Foundation

public enum KeystoreSecretType: String {
    case sr25519
    case ed25519
    case ecdsa
    case ethereum
}

public struct KeystoreData: Equatable {
    public let address: String?
    public let secretKeyData: Data
    public let publicKeyData: Data
    public let secretType: KeystoreSecretType

    public init(address: String?, secretKeyData: Data, publicKeyData: Data, secretType: KeystoreSecretType) {
        self.address = address
        self.secretKeyData = secretKeyData
        self.publicKeyData = publicKeyData
        self.secretType = secretType
    }
}
