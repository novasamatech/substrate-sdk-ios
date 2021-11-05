import Foundation
import IrohaCrypto

public protocol KeystoreInfoFactoryProtocol {
    func createInfo(from definition: KeystoreDefinition) throws -> KeystoreInfo
}

public enum KeystoreInfoFactoryError: Error {
    case unsupportedSecretType
    case unsupportedAddressType
}

public final class KeystoreInfoFactory: KeystoreInfoFactoryProtocol {
    public init() {}

    public func createInfo(from definition: KeystoreDefinition) throws -> KeystoreInfo {
        let maybeSecretTypeValue = definition.encoding.content.count > 1 ? definition.encoding.content[1] : nil

        guard let value = maybeSecretTypeValue, let secretType = KeystoreSecretType(rawValue: value) else {
            throw KeystoreInfoFactoryError.unsupportedSecretType
        }

        let chainType: ChainType?

        if let address = definition.address,
           let chainTypeValue = try? SS58AddressFactory().type(fromAddress: address) {
            chainType = chainTypeValue.uint16Value
        } else {
            chainType = nil
        }

        return KeystoreInfo(address: definition.address,
                            chainType: chainType,
                            secretType: secretType,
                            meta: definition.meta)
    }
}
