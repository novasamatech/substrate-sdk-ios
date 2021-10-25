import Foundation
import IrohaCrypto

open class SubstrateQREncoder: SubstrateQREncodable {
    let separator: String

    public init(separator: String = SubstrateQR.fieldsSeparator) {
        self.separator = separator
    }

    public func encode(info: SubstrateQRInfo) throws -> Data {
        var fields: [String] = [
            info.prefix,
            info.address,
            info.rawPublicKey.toHex(includePrefix: true)
        ]

        if let username = info.username {
            fields.append(username)
        }

        guard let data = fields.joined(separator: separator).data(using: .utf8) else {
            throw SubstrateQREncoderError.brokenData
        }

        return data
    }
}
