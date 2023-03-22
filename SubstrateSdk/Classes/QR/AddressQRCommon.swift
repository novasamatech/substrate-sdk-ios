import Foundation
import IrohaCrypto

public enum AddressQRCoderError: Error {
    case invalidAddress
}

public enum AddressQRValidator {
    static public func isAddressValid(
        _ address: String,
        format: QRAddressFormat,
        addressFactory: SS58AddressFactoryProtocol
    ) -> Bool {
        switch format {
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
