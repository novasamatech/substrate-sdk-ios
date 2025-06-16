import Foundation
import SubstrateSdk
import BigInt

public struct TransferArgs: Codable {
    public var dest: MultiAddress
    @StringCodable public var value: BigUInt
    
    public init(dest: MultiAddress, value: BigUInt) {
        self.dest = dest
        self.value = value
    }
}
