import Foundation
import IrohaCrypto
import TweetNacl

public protocol KeystoreExtracting {
    func extractFromDefinition(_ info: KeystoreDefinition,
                               password: String?) throws -> KeystoreData
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
    case missingPkcs8Header
    case missingPkcs8Divider
}

private enum KeystoreEncodingType: String {
    case scrypt = "scrypt"
    case xsalsa = "xsalsa20-poly1305"
}

private enum KeystoreEncodingContent: String {
    case pkcs8 = "pkcs8"
}

public struct KeystoreExtractor: KeystoreExtracting {
    static let nonceLength = 24
    static let encryptionKeyLength = 32
    static let pkcs8Header = Data(bytes: [48, 83, 2, 1, 1, 48, 5, 6, 3, 43, 101, 112, 4, 34, 4, 32])
    static let pkcs8Divider = Data(bytes: [161, 35, 3, 33, 0])

    public init() {}

    public func extractFromDefinition(_ info: KeystoreDefinition,
                                      password: String?) throws -> KeystoreData {
        guard let data = Data(base64Encoded: info.encoded) else {
            throw KeystoreExtractorError.invalidBase64
        }

        let keyDerivationName: String? = info.encoding.type.count > 0 ? info.encoding.type[0] : nil
        let cipherType: String? = info.encoding.type.count > 1 ? info.encoding.type[1] : nil

        let encodedData: Data

        if keyDerivationName == nil, cipherType == nil {
            encodedData = data
        } else if
            keyDerivationName == KeystoreEncodingType.scrypt.rawValue,
            cipherType == KeystoreEncodingType.xsalsa.rawValue {
            let scryptParameters = try ScryptParameters(data: data)

            let scryptData: Data

            if let passwordData = password?.data(using: .utf8) {
                scryptData = passwordData
            } else {
                scryptData = Data()
            }

            let encryptionKey = try IRScryptKeyDeriviation().deriveKey(from: scryptData,
                                                                       salt: scryptParameters.salt,
                                                                       scryptN: UInt(scryptParameters.scryptN),
                                                                       scryptP: UInt(scryptParameters.scryptP),
                                                                       scryptR: UInt(scryptParameters.scryptR),
                                                                       length: UInt(Self.encryptionKeyLength))

            let nonceStart = ScryptParameters.encodedLength
            let nonceEnd = ScryptParameters.encodedLength + Self.nonceLength
            let nonce = Data(data[nonceStart..<nonceEnd])
            let encryptedData = Data(data[nonceEnd...])

            encodedData = try NaclSecretBox.open(box: encryptedData, nonce: nonce, key: encryptionKey)
        } else {
            throw KeystoreExtractorError.unsupportedEncoding
        }

        return try decodePkcs8(data: encodedData, definition: info)
    }

    private func decodePkcs8(data: Data, definition: KeystoreDefinition) throws -> KeystoreData {
        let contentType = definition.encoding.content.count > 0 ? definition.encoding.content[0] : nil
        let cryptoTypeValue = definition.encoding.content.count > 1 ? definition.encoding.content[1] : nil

        guard contentType == KeystoreEncodingContent.pkcs8.rawValue else {
            throw KeystoreExtractorError.unsupportedContent
        }

        guard let value = cryptoTypeValue, let cryptoType = CryptoType(rawValue: value) else {
            throw KeystoreExtractorError.unsupportedCryptoType
        }

        guard data.starts(with: Self.pkcs8Header) else {
            throw KeystoreExtractorError.missingPkcs8Header
        }

        guard let dividerRange = data.firstRange(of: Self.pkcs8Divider) else {
            throw KeystoreExtractorError.missingPkcs8Divider
        }

        let secretStart = Self.pkcs8Header.count
        let secretEnd = dividerRange.startIndex

        let importedSecretData = Data(data[secretStart..<secretEnd])

        let secretKeyData: Data
        switch cryptoType {
        case .sr25519:
            secretKeyData = try SNPrivateKey(fromEd25519: importedSecretData).rawData()
        case .ed25519:
            secretKeyData = importedSecretData
        case .ecdsa:
            secretKeyData = importedSecretData
        }

        let publicStart = dividerRange.endIndex
        let publicKeyData = Data(data[publicStart...])

        return KeystoreData(address: definition.address,
                            secretKeyData: secretKeyData,
                            publicKeyData: publicKeyData,
                            cryptoType: cryptoType)
    }
}
