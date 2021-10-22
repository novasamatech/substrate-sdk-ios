import Foundation

public struct EthereumSignature: Codable {
    enum CodingKeys: String, CodingKey {
        case rPart = "r"
        case sPart = "s"
        case vPart = "v"
    }

    public let rPart: H256
    public let sPart: H256
    @StringCodable public var vPart: UInt8

    public init?(rawValue: Data) {
        guard rawValue.count == 65 else {
            return nil
        }

        rPart = H256(value: rawValue[0 ..< 32])
        sPart = H256(value: rawValue[32 ..< 64])
        vPart = rawValue[64]
    }

    public init(rPart: H256, sPart: H256, vPart: UInt8) {
        self.rPart = rPart
        self.sPart = sPart
        self.vPart = vPart
    }
}
