import Foundation

/// Plain field coding used by `@ScaleCodable` expansions. Overload resolution, not the macro,
/// picks the optional forms, so typealiased optionals are handled too.
public enum ScaleField {
    public static func encode<T: ScaleEncodable>(_ value: T, to encoder: ScaleEncoding) throws {
        try value.encode(scaleEncoder: encoder)
    }

    public static func decode<T: ScaleDecodable>(from decoder: ScaleDecoding) throws -> T {
        try T(scaleDecoder: decoder)
    }

    public static func encode<T: ScaleEncodable>(_ value: T?, to encoder: ScaleEncoding) throws {
        guard let value else {
            encoder.appendRaw(data: Data([0]))
            return
        }

        encoder.appendRaw(data: Data([1]))
        try value.encode(scaleEncoder: encoder)
    }

    public static func decode<T: ScaleDecodable>(from decoder: ScaleDecoding) throws -> T? {
        try decodeOptional(from: decoder) { try T(scaleDecoder: decoder) }
    }

    /// `Option<bool>` is a single byte: 0 none, 1 true, 2 false.
    public static func encode(_ value: Bool?, to encoder: ScaleEncoding) throws {
        try ScaleBoolOption(value: value).encode(scaleEncoder: encoder)
    }

    public static func decode(from decoder: ScaleDecoding) throws -> Bool? {
        try ScaleBoolOption(scaleDecoder: decoder).value
    }

    static func decodeOptional<T>(from decoder: ScaleDecoding, decodeValue: () throws -> T) throws -> T? {
        let mode = try decoder.readAndConfirm(count: 1)[0]

        switch mode {
        case 0:
            return nil
        case 1:
            return try decodeValue()
        default:
            throw ScaleOptionDecodingError.invalidPrefix
        }
    }

    static func encodeOptional<T>(_ value: T?, to encoder: ScaleEncoding, encodeValue: (T) throws -> Void) throws {
        guard let value else {
            encoder.appendRaw(data: Data([0]))
            return
        }

        encoder.appendRaw(data: Data([1]))
        try encodeValue(value)
    }
}
