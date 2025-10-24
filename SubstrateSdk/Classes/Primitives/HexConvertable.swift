import Foundation
import BigInt

public protocol HexConvertable {
    init(hexString: String) throws
    func toHexWithPrefix() -> String
}

extension Data: HexConvertable {
    public func toHexWithPrefix() -> String {
        toHex(includePrefix: true)
    }
}

extension BigUInt: HexConvertable {
    public func toHexWithPrefix() -> String {
        toHexString()
    }

    public init(hexString: String) throws {
        guard let value = BigUInt.fromHexString(hexString) else {
            throw HexConvertableError.broken(hexString)
        }

        self = value
    }
}

public enum HexConvertableError: Error {
    case broken(String)
}

extension Bool: HexConvertable {
    public func toHexWithPrefix() -> String {
        BigUInt(self ? 1 : 0).toHexString()
    }

    public init(hexString: String) throws {
        guard let value = BigUInt.fromHexString(hexString) else {
            throw HexConvertableError.broken(hexString)
        }

        self = value == 1
    }
}

public extension BigUInt {
    static func fromHexString(_ hex: String) -> BigUInt? {
        let prefix = "0x"

        if hex.hasPrefix(prefix) {
            let filtered = String(hex.suffix(hex.count - prefix.count))
            return BigUInt(filtered, radix: 16)
        } else {
            return BigUInt(hex, radix: 16)
        }
    }

    func toHexString() -> String {
        let prefix = "0x"

        return prefix + String(self, radix: 16)
    }
}
