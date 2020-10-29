import Foundation

public struct SubstrateQRInfo: Equatable {
    public let prefix: String
    public let address: String
    public let rawPublicKey: Data
    public let username: String?

    public init(prefix: String = SubstrateQR.prefix,
                address: String,
                rawPublicKey: Data,
                username: String?) {
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

public struct SubstrateQR {
    public static let prefix: String = "substrate"
    public static let fieldsSeparator: String = ":"
}
