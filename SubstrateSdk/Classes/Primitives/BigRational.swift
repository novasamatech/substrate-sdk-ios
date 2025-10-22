import Foundation
import BigInt

public struct BigRational: Hashable, Equatable {
    public let numerator: BigUInt
    public let denominator: BigUInt

    public init(numerator: BigUInt, denominator: BigUInt) {
        self.numerator = numerator
        self.denominator = denominator
    }
    
    public func mul(value: BigUInt) -> BigUInt {
        value * numerator / denominator
    }
}

public extension BigUInt {
    func sub(rational: BigRational) -> BigRational? {
        let numerator = self * rational.denominator

        guard numerator >= rational.numerator else {
            return nil
        }

        return BigRational(
            numerator: numerator - rational.numerator,
            denominator: rational.denominator
        )
    }
}

public extension BigRational {
    static func percent(of numerator: BigUInt) -> BigRational {
        .init(numerator: numerator, denominator: 100)
    }

    static func permillPercent(of numerator: BigUInt) -> BigRational {
        .init(numerator: numerator, denominator: 1_000_000)
    }

    static func fixedU128(value: BigUInt) -> BigRational {
        .init(
            numerator: value,
            denominator: 1_000_000_000_000_000_000
        )
    }
}

public extension BigRational {
    static func fraction(from number: Decimal) -> BigRational? {
        let decimalNumber = NSDecimalNumber(decimal: number)
        guard decimalNumber.doubleValue.remainder(dividingBy: 1) != 0 else {
            return number.toSubstrateAmount(precision: 0).map {
                BigRational(numerator: $0, denominator: 1)
            }
        }
        let scale = -number.exponent
        if let numerator = number.toSubstrateAmount(precision: Int16(scale)),
           let denominator = Decimal(1).toSubstrateAmount(precision: Int16(scale)) {
            return .init(numerator: numerator, denominator: denominator)
        }

        return nil
    }
}

public extension BigRational {
    var decimalValue: Decimal? {
        guard denominator != 0 else {
            return nil
        }
        let numerator = numerator.decimal(precision: 0)
        let denominator = denominator.decimal(precision: 0)
        return numerator / denominator
    }

    var decimalOrZeroValue: Decimal {
        decimalValue ?? 0
    }

    func decimalOrError() throws -> Decimal {
        guard let value = decimalValue else {
            throw BigRationalError.decimalConversionFailed
        }

        return value
    }
}

public enum BigRationalError: Error {
    case decimalConversionFailed
}
