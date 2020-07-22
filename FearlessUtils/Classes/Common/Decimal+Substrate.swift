import Foundation
import BigInt

public extension Decimal {
    static func fromSubstrateAmount(_ value: BigUInt) -> Decimal? {
        let valueString = String(value)

        guard let decimalValue = Decimal(string: valueString) else {
            return nil
        }

        return (decimalValue as NSDecimalNumber).multiplying(byPowerOf10: -12).decimalValue
    }

    func toSubstrateAmount() -> BigUInt? {
        let valueString = (self as NSDecimalNumber).multiplying(byPowerOf10: 12).stringValue
        return BigUInt(valueString)
    }
}
