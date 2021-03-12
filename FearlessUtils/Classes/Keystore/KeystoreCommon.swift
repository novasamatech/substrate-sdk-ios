import Foundation

public protocol KeystoreExtracting {
    func extractFromDefinition(_ info: KeystoreDefinition,
                               password: String?) throws -> KeystoreData
}

public protocol KeystoreBuilding {
    func with(name: String) -> Self
    func with(creationDate: Date) -> Self
    func with(genesisHash: String) -> Self

    func build(from data: KeystoreData, password: String?) throws -> KeystoreDefinition
}

public enum KeystoreExtractorError: Error {
    case invalidBase64
    case missingScryptSalt
    case missingScryptN
    case missingScryptP
    case missingScryptR
    case unsupportedEncoding
    case unsupportedContent
    case unsupportedCryptoType
    case invalidPasswordFormat
    case missingPkcs8Header
    case missingPkcs8Divider
}

public enum KeystoreBuilderError: Error {
    case invalidPasswordFormat
}

enum KeystoreEncodingType: String {
    case scrypt = "scrypt"
    case xsalsa = "xsalsa20-poly1305"
}

enum KeystoreEncodingContent: String {
    case pkcs8
}

public struct KeystoreConstants {
    public static let nonceLength = 24
    public static let encryptionKeyLength = 32
    public static let pkcs8Header = Data(bytes: [48, 83, 2, 1, 1, 48, 5, 6, 3, 43, 101, 112, 4, 34, 4, 32])
    public static let pkcs8Divider = Data(bytes: [161, 35, 3, 33, 0])
    public static let version = 3
}
