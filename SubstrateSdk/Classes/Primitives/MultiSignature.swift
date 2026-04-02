import Foundation

enum MultiSignatureError: Error {
    case unexpectedType
}

public enum MultiSignature: Codable {
    static let sr25519Field = "Sr25519"
    static let ed25519Field = "Ed25519"
    static let ecdsaField = "Ecdsa"

    static let ed25519Index: UInt8 = 0
    static let sr25519Index: UInt8 = 1
    static let ecdsaIndex: UInt8 = 2

    static let sr25519Length = 64
    static let ed25519Length = 64
    static let ecdsaLength = 65

    case sr25519(data: Data)
    case ed25519(data: Data)
    case ecdsa(data: Data)

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(String.self)

        let data: Data

        // we support both data and byte arrays representation
        if let dataRepresentation = try? container.decode(Data.self) {
            data = dataRepresentation
        } else {
            let byteArray = try container.decode([StringScaleMapper<UInt8>].self).map(\.value)
            data = Data(byteArray)
        }

        switch type {
        case Self.sr25519Field:
            self = .sr25519(data: data)
        case Self.ed25519Field:
            self = .ed25519(data: data)
        case Self.ecdsaField:
            self = .ecdsa(data: data)
        default:
            throw MultiSignatureError.unexpectedType
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        switch self {
        case let .sr25519(data):
            try container.encode(Self.sr25519Field)
            try container.encode(data)
        case let .ed25519(data):
            try container.encode(Self.ed25519Field)
            try container.encode(data)
        case let .ecdsa(data):
            try container.encode(Self.ecdsaField)
            try container.encode(data)
        }
    }
}

extension MultiSignature: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case let .ed25519(data):
            try Self.ed25519Index.encode(scaleEncoder: scaleEncoder)
            scaleEncoder.appendRaw(data: data)
        case let .sr25519(data):
            try Self.sr25519Index.encode(scaleEncoder: scaleEncoder)
            scaleEncoder.appendRaw(data: data)
        case let .ecdsa(data):
            try Self.ecdsaIndex.encode(scaleEncoder: scaleEncoder)
            scaleEncoder.appendRaw(data: data)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        switch index {
        case Self.sr25519Index:
            let data = try scaleDecoder.readAndConfirm(count: Self.sr25519Length)
            self = .sr25519(data: data)
        case Self.ed25519Index:
            let data = try scaleDecoder.readAndConfirm(count: Self.ed25519Length)
            self = .ed25519(data: data)
        case Self.ecdsaIndex:
            let data = try scaleDecoder.readAndConfirm(count: Self.ecdsaLength)
            self = .ecdsa(data: data)
        default:
            throw MultiSignatureError.unexpectedType
        }
    }
}
