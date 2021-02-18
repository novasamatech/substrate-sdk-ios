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

struct EncodingContainer<T: Encodable>: Encodable {
    let value: T
}

struct DecodingContainer<T: Decodable>: Decodable {
    let value: T
}

struct JsonContainer: Codable {
    let value: JSON
}

public extension Encodable {
    func toScaleCompatibleJSON() throws -> JSON {
        let container = EncodingContainer(value: self)

        let data = try JSONEncoder.scaleCompatible().encode(container)
        let json = try JSONDecoder.scaleCompatible().decode(JsonContainer.self, from: data).value

        return json
    }
}

public extension JSON {
    func map<T: Decodable>(to type: T.Type) throws -> T {
        let encoder = JSONEncoder.scaleCompatible()
        let encodingContainer = JsonContainer(value: self)
        let data = try encoder.encode(encodingContainer)

        let decoder = JSONDecoder.scaleCompatible()
        return try decoder.decode(DecodingContainer<T>.self, from: data).value
    }
}

public extension DynamicScaleEncoding {
    func append<T: Encodable>(_ codable: T, ofType type: String) throws {
        let json = try codable.toScaleCompatibleJSON()
        try append(json: json, type: type)
    }
}

public extension DynamicScaleDecoding {
    func read<T: Decodable>(of type: String) throws -> T {
        let json = try read(type: type)
        return try json.map(to: T.self)
    }
}
