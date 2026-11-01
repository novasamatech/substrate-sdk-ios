import BigInt
import Foundation

/// Compact coding for `@ScaleCompact` fields. Decoding narrows with `init(exactly:)`,
/// so an out-of-range value throws instead of trapping.
public enum ScaleCompact {
    public static func encode<T: FixedWidthInteger & UnsignedInteger>(_ value: T, to encoder: ScaleEncoding) throws {
        try BigUInt(value).encode(scaleEncoder: encoder)
    }

    public static func decode<T: FixedWidthInteger & UnsignedInteger>(from decoder: ScaleDecoding) throws -> T {
        guard let value = T(exactly: try BigUInt(scaleDecoder: decoder)) else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        return value
    }

    public static func encode(_ value: BigUInt, to encoder: ScaleEncoding) throws {
        try value.encode(scaleEncoder: encoder)
    }

    public static func decode(from decoder: ScaleDecoding) throws -> BigUInt {
        try BigUInt(scaleDecoder: decoder)
    }

    public static func encode<T: FixedWidthInteger & UnsignedInteger>(_ value: T?, to encoder: ScaleEncoding) throws {
        try ScaleField.encodeOptional(value, to: encoder) { try encode($0, to: encoder) }
    }

    public static func decode<T: FixedWidthInteger & UnsignedInteger>(from decoder: ScaleDecoding) throws -> T? {
        try ScaleField.decodeOptional(from: decoder) { try decode(from: decoder) as T }
    }

    public static func encode(_ value: BigUInt?, to encoder: ScaleEncoding) throws {
        try ScaleField.encodeOptional(value, to: encoder) { try encode($0, to: encoder) }
    }

    public static func decode(from decoder: ScaleDecoding) throws -> BigUInt? {
        try ScaleField.decodeOptional(from: decoder) { try decode(from: decoder) as BigUInt }
    }

    public static func encode<T: FixedWidthInteger & UnsignedInteger>(_ values: [T], to encoder: ScaleEncoding) throws {
        try BigUInt(values.count).encode(scaleEncoder: encoder)

        for value in values {
            try encode(value, to: encoder)
        }
    }

    public static func decode<T: FixedWidthInteger & UnsignedInteger>(from decoder: ScaleDecoding) throws -> [T] {
        let count: UInt64 = try decode(from: decoder)

        // every compact element takes at least one byte, so a larger count is malformed input
        guard count <= UInt64(decoder.remained) else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        var values: [T] = []
        values.reserveCapacity(Int(count))

        for _ in 0 ..< count {
            values.append(try decode(from: decoder))
        }

        return values
    }
}
