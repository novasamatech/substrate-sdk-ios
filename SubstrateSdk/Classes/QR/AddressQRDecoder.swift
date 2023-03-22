import Foundation
import IrohaCrypto

public protocol AddressQRDecodable {
    func decode(data: Data) throws -> String
}

open class AddressQRDecoder: AddressQRDecodable {
    public let addressFormat: QRAddressFormat

    private lazy var addressFactory = SS58AddressFactory()

    public init(addressFormat: QRAddressFormat) {
        self.addressFormat = addressFormat
    }

    public func decode(data: Data) throws -> String {
        guard
            let addressString = String(data: data, encoding: .utf8),
            AddressQRValidator.isAddressValid(
                addressString,
                format: addressFormat,
                addressFactory: addressFactory
            ) else {
                throw AddressQRCoderError.invalidAddress
            }

        return addressString
    }
}
