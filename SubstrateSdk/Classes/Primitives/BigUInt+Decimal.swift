import Foundation
import BigInt

public extension BigUInt {
    func decimal(precision: UInt16 = 0) -> Decimal {
        Decimal.fromSubstrateAmount(
            self,
            precision: Int16(precision)
        ) ?? 0
    }
}
