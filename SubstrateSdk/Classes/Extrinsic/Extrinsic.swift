import Foundation
import BigInt

public struct ExtrinsicConstants {
    static let version: UInt8 = 4
    static let signedMask: UInt8 = 1 << 7
}

public struct Extrinsic: Codable {
    enum CodingKeys: String, CodingKey {
        case signature
        case call
    }

    public let signature: ExtrinsicSignature?
    public let call: JSON

    public init(signature: ExtrinsicSignature?, call: JSON) {
        self.signature = signature
        self.call = call
    }
}

public struct ExtrinsicSignature: Codable {
    enum CodingKeys: String, CodingKey {
        case address
        case signature
        case extra
    }

    public let address: JSON
    public let signature: JSON
    public let extra: ExtrinsicExtra

    public init(address: JSON, signature: JSON, extra: ExtrinsicExtra) {
        self.address = address
        self.signature = signature
        self.extra = extra
    }
}
