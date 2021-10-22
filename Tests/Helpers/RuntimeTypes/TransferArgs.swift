import Foundation
import FearlessUtils
import BigInt

struct TransferArgs: Codable {
    var dest: MultiAddress
    @StringCodable var value: BigUInt
}
