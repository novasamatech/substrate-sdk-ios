import Foundation
import IrohaCrypto
import TweetNacl

public class KeystoreBuilder {
    private var name: String?
    private var creationDate = Date()
    private var genesisHash: String?

    public init() {}
}

extension KeystoreBuilder: KeystoreBuilding {
    public func with(name: String) -> Self {
        self.name = name
        return self
    }

    public func with(creationDate: Date) -> Self {
        self.creationDate = creationDate
        return self
    }

    public func with(genesisHash: String) -> Self {
        self.genesisHash = genesisHash
        return self
    }

    public func build(from data: KeystoreData, password: String?) throws -> KeystoreDefinition {
        let scryptParameters = try ScryptParameters()

        let scryptData: Data

        if let password = password {
            guard let passwordData = password.data(using: .utf8) else {
                throw KeystoreExtractorError.invalidPasswordFormat
            }

            scryptData = passwordData
        } else {
            scryptData = Data()
        }

        let encryptionKey = try IRScryptKeyDeriviation()
            .deriveKey(from: scryptData,
                       salt: scryptParameters.salt,
                       scryptN: UInt(scryptParameters.scryptN),
                       scryptP: UInt(scryptParameters.scryptP),
                       scryptR: UInt(scryptParameters.scryptR),
                       length: UInt(KeystoreConstants.encryptionKeyLength))

        let nonce = try Data.generateRandomBytes(of: KeystoreConstants.nonceLength)

        let secretKeyData: Data
        switch data.cryptoType {
        case .sr25519:
            secretKeyData = try SNPrivateKey(rawData: data.secretKeyData).toEd25519Data()
        case .ed25519:
            secretKeyData = data.secretKeyData
        case .ecdsa:
            secretKeyData = data.secretKeyData
        }

        let pcksData = KeystoreConstants.pkcs8Header + secretKeyData +
            KeystoreConstants.pkcs8Divider + data.publicKeyData
        let encrypted = try NaclSecretBox.secretBox(message: pcksData, nonce: nonce, key: encryptionKey)
        let encoded = scryptParameters.encode() + nonce + encrypted

        let encodingType = [KeystoreEncodingType.scrypt.rawValue, KeystoreEncodingType.xsalsa.rawValue]
        let encodingContent = [KeystoreEncodingContent.pkcs8.rawValue, data.cryptoType.rawValue]
        let keystoreEncoding = KeystoreEncoding(content: encodingContent,
                                                type: encodingType,
                                                version: String(KeystoreConstants.version))

        let meta = KeystoreMeta(name: name,
                                createdAt: Int64(creationDate.timeIntervalSince1970),
                                genesisHash: genesisHash)

        return KeystoreDefinition(address: data.address,
                                  encoded: encoded.base64EncodedString(),
                                  encoding: keystoreEncoding,
                                  meta: meta)
    }
}
