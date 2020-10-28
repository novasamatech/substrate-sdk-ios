import Foundation

extension Data {
    func matchAccountId(_ accountId: Data) -> Bool {
        if accountId == self {
            return true
        }

        return accountId == (try? self.blake2b32())
    }
}
