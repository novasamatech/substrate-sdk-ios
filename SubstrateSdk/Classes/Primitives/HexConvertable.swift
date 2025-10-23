import Foundation

public protocol HexConvertable {
    init(hexString: String) throws
    func toHexWithPrefix() -> String
}

extension Data: HexConvertable {
    public func toHexWithPrefix() -> String {
        toHex(includePrefix: true)
    }
}
