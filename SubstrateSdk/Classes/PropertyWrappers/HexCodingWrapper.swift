import Foundation
import BigInt

@propertyWrapper
public struct HexCodable<T: HexConvertable>: Codable {
    public let wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let hexString = try container.decode(String.self)

        wrappedValue = try T(hexString: hexString)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(wrappedValue.toHexWithPrefix())
    }
}

@propertyWrapper
public struct OptionHexCodable<T: HexConvertable>: Codable {
    public let wrappedValue: T?

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        wrappedValue = try HexCodable(from: decoder).wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let wrappedValue {
            try container.encode(wrappedValue.toHexWithPrefix())
        } else {
            try container.encodeNil()
        }
    }
}

public extension KeyedDecodingContainer {
    func decode<T: HexConvertable>(_ type: OptionHexCodable<T>.Type, forKey key: K) throws -> OptionHexCodable<T> {
        if let value = try decodeIfPresent(type, forKey: key) {
            return value
        }

        return OptionHexCodable(wrappedValue: nil)
    }
}
