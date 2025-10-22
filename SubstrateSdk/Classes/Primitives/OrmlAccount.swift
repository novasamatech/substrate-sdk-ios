import Foundation
import BigInt

public struct OrmlAccount: Codable, Equatable {
    @StringCodable var free: BigUInt
    @StringCodable var reserved: BigUInt
    @StringCodable var frozen: BigUInt

    public var total: BigUInt { free + reserved }
}
