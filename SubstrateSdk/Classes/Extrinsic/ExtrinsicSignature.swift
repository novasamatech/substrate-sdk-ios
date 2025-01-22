import Foundation
import BigInt

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
