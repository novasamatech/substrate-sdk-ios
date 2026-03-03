import Foundation
import BigInt

extension BigUInt: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(description, radix: 10)
    }
}

@propertyWrapper
public struct BytesCodable: Codable, Hashable {
    public var wrappedValue: Data

    public init(wrappedValue: Data) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let byteArray = try? container.decode([StringScaleMapper<UInt8>].self) {
            wrappedValue = Data(byteArray.map(\.value))
        } else {
            wrappedValue = try container.decode(Data.self)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let bytes = wrappedValue.map { StringScaleMapper(value: $0) }

        try container.encode(bytes)
    }
}

@propertyWrapper
public struct OptionalBytesCodable: Codable, Hashable {
    public var wrappedValue: Data?
    
    public init(wrappedValue: Data?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
        } else if let byteArray = try? container.decode([StringScaleMapper<UInt8>].self) {
            wrappedValue = Data(byteArray.map(\.value))
        } else {
            wrappedValue = try container.decode(Data.self)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let data = wrappedValue {
            let bytes = data.map { StringScaleMapper(value: $0) }
            try container.encode(bytes)
        } else {
            try container.encodeNil()
        }
    }
}

@propertyWrapper
public struct StringCodable<T: LosslessStringConvertible & Hashable>: Codable, Hashable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let strValue = try container.decode(String.self)

        guard let value = T(strValue) else {
            throw DecodingError
                .dataCorrupted(.init(codingPath: container.codingPath, debugDescription: ""))
        }

        wrappedValue = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.description)
    }
}

@propertyWrapper
public struct OptionStringCodable<T: LosslessStringConvertible & Hashable>: Codable, Hashable {
    public var wrappedValue: T?

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            wrappedValue = nil
        } else {
            let strValue = try container.decode(String.self)

            guard let value = T(strValue) else {
                throw DecodingError
                    .dataCorrupted(.init(codingPath: container.codingPath, debugDescription: ""))
            }

            wrappedValue = value
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let value = wrappedValue?.description {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

public extension KeyedDecodingContainer {
    func decode<T: LosslessStringConvertible>(
        _ type: OptionStringCodable<T>.Type,
        forKey key: K
    ) throws -> OptionStringCodable<T> {
        if let value = try decodeIfPresent(type, forKey: key) {
            return value
        }

        return OptionStringCodable(wrappedValue: nil)
    }
}

@propertyWrapper
public struct NullCodable<T: Codable>: Codable {
    public var wrappedValue: T?

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            wrappedValue = nil
        } else {
            wrappedValue = try container.decode(T.self)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let value = wrappedValue {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }
}

extension NullCodable: Equatable where T: Equatable {}

extension NullCodable: Hashable where T: Hashable {}
