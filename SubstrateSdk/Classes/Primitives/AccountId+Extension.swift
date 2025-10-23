import Foundation

public extension AccountId {
    static func zeroAccountId(of size: Int) -> AccountId {
        AccountId(repeating: 0, count: size)
    }
}
