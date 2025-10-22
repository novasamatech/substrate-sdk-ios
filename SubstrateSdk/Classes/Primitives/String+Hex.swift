import Foundation

public extension String {
    func withHexPrefix() -> String {
        if hasPrefix("0x") {
            return self
        } else {
            return "0x" + self
        }
    }
}
