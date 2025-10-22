import Foundation
import BigInt

public struct OrmlAccount: Codable, Equatable {
    @StringCodable public var free: BigUInt
    @StringCodable public var reserved: BigUInt
    @StringCodable public var frozen: BigUInt

    public var total: BigUInt { free + reserved }
}
