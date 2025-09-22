import Foundation

public struct SubstrateQRInfo: Equatable {
    public let prefix: String
    public let address: String
    public let rawPublicKey: Data
    public let username: String?

    public init(
        prefix: String = SubstrateQR.prefix,
        address: String,
        rawPublicKey: Data,
        username: String?
    ) {
        self.prefix = prefix
        self.address = address
        self.rawPublicKey = rawPublicKey
        self.username = username
    }
}

public protocol SubstrateQREncodable {
    func encode(info: SubstrateQRInfo) throws -> Data
}

public protocol SubstrateQRDecodable {
    func decode(data: Data) throws -> SubstrateQRInfo
}

public enum SubstrateQREncoderError: Error, Equatable {
    case brokenData
}

public enum SubstrateQRDecoderError: Error, Equatable {
    case brokenFormat
    case unexpectedNumberOfFields
    case undefinedPrefix
    case accountIdMismatch
}

public enum SubstrateQR {
    public static let prefix: String = "substrate"
    public static let fieldsSeparator: String = ":"

    public static func isSubstrateQR(data: Data) -> Bool {
        if
            let fields = String(data: data, encoding: .utf8)?.components(separatedBy: Self.fieldsSeparator),
            fields.count >= 3, fields.count <= 4,
            fields[0] == prefix {
            return true
        } else {
            return false
        }
    }
}

public enum QRAddressFormat {
    public static let ethereumAddressLength = 20

    case substrate(type: ChainType)
    case ethereum
}
