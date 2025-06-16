import Foundation
import SubstrateSdk
import BigInt

public struct TransientValidationData: Codable, Equatable {
    @StringCodable public var maxCodeSize: UInt32
    @StringCodable public var maxHeadDataSize: UInt32
    @StringCodable public var balance: BigUInt
    @OptionStringCodable public var codeUpgradeAllowed: UInt32?
    @StringCodable public var dmqLength: UInt32
    
    public init(
        maxCodeSize: UInt32,
        maxHeadDataSize: UInt32,
        balance: BigUInt,
        codeUpgradeAllowed: UInt32? = nil,
        dmqLength: UInt32
    ) {
        self.maxCodeSize = maxCodeSize
        self.maxHeadDataSize = maxHeadDataSize
        self.balance = balance
        self.codeUpgradeAllowed = codeUpgradeAllowed
        self.dmqLength = dmqLength
    }
}
