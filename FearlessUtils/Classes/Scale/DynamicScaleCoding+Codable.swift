import Foundation

public class HexCodingStrategy {
    static func encoding(data: Data, encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let hex = data.toHex(includePrefix: true)
        try container.encode(hex)
    }

    static func decoding(with decoder: Decoder) throws -> Data {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        return try Data(hexString: hex)
    }
}

public extension JSONEncoder {
    static func scaleCompatible() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .custom(HexCodingStrategy.encoding(data:encoder:))
        return encoder
    }
}

public extension JSONDecoder {
    static func scaleCompatible() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .custom(HexCodingStrategy.decoding(with:))
        return decoder
    }
}

private struct EncodingContainer<T: Encodable>: Encodable {
    let value: T
}

private struct DecodingContainer<T: Decodable>: Decodable {
    let value: T
}

private struct JsonContainer: Codable {
    let value: JSON
}

public extension DynamicScaleEncoding {
    func append<T: Encodable>(_ codable: T, ofType type: String) throws {
        let encoder = JSONEncoder.scaleCompatible()

        let container = EncodingContainer(value: codable)

        let data = try encoder.encode(container)

        let decoder = JSONDecoder.scaleCompatible()

        let json = try decoder.decode(JsonContainer.self, from: data).value

        try append(json: json, type: type)
    }
}

public extension DynamicScaleDecoding {
    func read<T: Decodable>(of type: String) throws -> T {
        let json = try read(type: type)

        let encoder = JSONEncoder.scaleCompatible()

        let encodingContainer = JsonContainer(value: json)
        let data = try encoder.encode(encodingContainer)

        let decoder = JSONDecoder.scaleCompatible()

        return try decoder.decode(DecodingContainer<T>.self, from: data).value
    }
}
