import Foundation
import IrohaCrypto

public protocol AddressQRDecodable {
    func decode(data: Data) throws -> String
}

public enum AddressQRDecoderError: Error {
    case invalidAddress
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
            isAddressValid(addressString) else {
                throw AddressQRDecoderError.invalidAddress
            }

        return addressString
    }

    private func isAddressValid(_ address: String) -> Bool {
        switch addressFormat {
        case let .substrate(type):
            return (try? addressFactory.accountId(fromAddress: address, type: type)) != nil
        case .ethereum:
            guard let addressData = try? Data(hexString: address) else {
                return false
            }

            return addressData.count == QRAddressFormat.ethereumAddressLength
        }
    }
}
