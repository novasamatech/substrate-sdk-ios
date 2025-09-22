import Foundation
import SubstrateSdk
import BigInt

public struct ValidatorPrefs: Codable, Equatable {
    @StringCodable public var commission: BigUInt
    public let blocked: Bool
    
    public init(commission: BigUInt, blocked: Bool) {
        self.commission = commission
        self.blocked = blocked
    }
}
