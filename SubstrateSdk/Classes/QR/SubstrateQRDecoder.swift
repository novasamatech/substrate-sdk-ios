import Foundation
import IrohaCrypto

open class SubstrateQRDecoder: SubstrateQRDecodable {
    public let addressFormat: QRAddressFormat?
    public let separator: String
    public let prefix: String

    private lazy var addressFactory = SS58AddressFactory()

    public init(
        addressFormat: QRAddressFormat? = nil,
        prefix: String = SubstrateQR.prefix,
        separator: String = SubstrateQR.fieldsSeparator
    ) {
        self.prefix = prefix
        self.addressFormat = addressFormat
        self.separator = separator
    }

    public func decode(data: Data) throws -> SubstrateQRInfo {
        guard let fields = String(data: data, encoding: .utf8)?
            .components(separatedBy: separator) else {
            throw SubstrateQRDecoderError.brokenFormat
        }

        guard fields.count >= 3, fields.count <= 4 else {
            throw SubstrateQRDecoderError.unexpectedNumberOfFields
        }

        guard fields[0] == prefix else {
            throw SubstrateQRDecoderError.undefinedPrefix
        }

        let address = fields[1]
        let publicKey = try Data(hexString: fields[2])

        if let addressFormat = addressFormat {
            switch addressFormat {
            case .substrate(let type):
                let accountId = try addressFactory.accountId(fromAddress: address, type: type)

                guard publicKey.matchPublicKeyToAccountId(accountId) else {
                    throw SubstrateQRDecoderError.accountIdMismatch
                }
            case .ethereum:
                let accountId = try Data(hexString: address)

                let expectedAccountId = try publicKey.ethereumAddressFromPublicKey()

                guard accountId == expectedAccountId else {
                    throw SubstrateQRDecoderError.accountIdMismatch
                }
            }
        }

        let username = fields.count > 3 ? fields[3] : nil

        return SubstrateQRInfo(
            prefix: prefix,
            address: address,
            rawPublicKey: publicKey,
            username: username
        )
    }
}
