import Foundation
import IrohaCrypto

public protocol KeystoreInfoFactoryProtocol {
    func createInfo(from definition: KeystoreDefinition) throws -> KeystoreInfo
}

public enum KeystoreInfoFactoryError: Error {
    case unsupportedCryptoType
    case unsupportedAddressType
}

public final class KeystoreInfoFactory: KeystoreInfoFactoryProtocol {
    public func createInfo(from definition: KeystoreDefinition) throws -> KeystoreInfo {
        let cryptoTypeValue = definition.encoding.content.count > 1 ? definition.encoding.content[1] : nil

        guard let value = cryptoTypeValue, let cryptoType = CryptoType(rawValue: value) else {
            throw KeystoreInfoFactoryError.unsupportedCryptoType
        }

        let addressTypeValue = try SS58AddressFactory().type(fromAddress: definition.address)

        guard let addressType = SNAddressType(rawValue: addressTypeValue.uint8Value) else {
            throw KeystoreInfoFactoryError.unsupportedAddressType
        }

        return KeystoreInfo(address: definition.address,
                            addressType: addressType,
                            cryptoType: cryptoType,
                            meta: definition.meta)
    }
}
