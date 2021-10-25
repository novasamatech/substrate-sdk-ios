import Foundation
import SubstrateSdk
import BigInt

struct TransferArgs: Codable {
    var dest: MultiAddress
    @StringCodable var value: BigUInt
}
