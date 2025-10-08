import Foundation
import BigInt

public extension Substrate.WeightV2 {
    static var zero: Self {
        Substrate.WeightV2(refTime: 0, proofSize: 0)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        Substrate.WeightV2(
            refTime: lhs.refTime + rhs.refTime,
            proofSize: lhs.proofSize + rhs.proofSize
        )
    }
}
