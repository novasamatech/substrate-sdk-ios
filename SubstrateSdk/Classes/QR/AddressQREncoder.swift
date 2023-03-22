import Foundation
import IrohaCrypto

public protocol AddressQREncodable {
    func encode(address: String) throws -> Data
}

open class AddressQREncoder: AddressQREncodable {
    public let addressFormat: QRAddressFormat

    private lazy var addressFactory = SS58AddressFactory()

    public init(addressFormat: QRAddressFormat) {
        self.addressFormat = addressFormat
    }

    public func encode(address: String) throws -> Data {
        guard
            AddressQRValidator.isAddressValid(address, format: addressFormat, addressFactory: addressFactory),
            let data = address.data(using: .utf8) else {
            throw AddressQRCoderError.invalidAddress
        }

        return data
    }
}
