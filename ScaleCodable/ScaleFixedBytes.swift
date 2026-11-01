import Foundation

/// Raw fixed-length bytes for `@ScaleFixed(n)` fields.
public enum ScaleFixedBytes {
    public static func encode(_ data: Data, length: Int, to encoder: ScaleEncoding) throws {
        guard data.count == length else {
            throw ScaleCodingError.unexpectedEncodedValue
        }

        encoder.appendRaw(data: data)
    }

    public static func decode(length: Int, from decoder: ScaleDecoding) throws -> Data {
        try decoder.readAndConfirm(count: length)
    }

    public static func encode(_ data: Data?, length: Int, to encoder: ScaleEncoding) throws {
        try ScaleField.encodeOptional(data, to: encoder) { try encode($0, length: length, to: encoder) }
    }

    public static func decode(length: Int, from decoder: ScaleDecoding) throws -> Data? {
        try ScaleField.decodeOptional(from: decoder) { try decode(length: length, from: decoder) as Data }
    }
}
