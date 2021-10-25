import Foundation
import SubstrateSdk
import BigInt

struct TransientValidationData: Codable, Equatable {
   @StringCodable var maxCodeSize: UInt32
   @StringCodable var maxHeadDataSize: UInt32
   @StringCodable var balance: BigUInt
   @OptionStringCodable var codeUpgradeAllowed: UInt32?
   @StringCodable var dmqLength: UInt32
}
