import Foundation

public enum MultiSigner: Hashable {
    public static let ed25519Field = "Ed25519"
    public static let sr25519Field = "Sr25519"
    public static let ecdsaField = "Ecdsa"
    
    static let ed25519Index: UInt8 = 0
    static let sr25519Index: UInt8 = 1
    static let ecdsaIndex: UInt8 = 2
    
    static let sr25519Length = 32
    static let ed25519Length = 32
    static let ecdsaLength = 33
    
    case ed25519(_ pubKey: Data)
    case sr25519(_ pubKey: Data)
    case ecdsa(_ pubKey: Data)

    public func getAccountId() throws -> AccountId {
        switch self {
        case let .ed25519(pubKey):
            pubKey
        case let .sr25519(pubKey):
            pubKey
        case let .ecdsa(pubKey):
            try pubKey.blake2b32()
        }
    }
}

extension MultiSigner: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(String.self)
        let bytes = try container.decode([StringScaleMapper<UInt8>].self).map(\.value)
        let data = Data(bytes)

        switch type {
        case Self.ed25519Field:
            self = .ed25519(data)
        case Self.sr25519Field:
            self = .sr25519(data)
        case Self.ecdsaField:
            self = .ecdsa(data)
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unexpected type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        let data: Data

        switch self {
        case let .ed25519(value):
            try container.encode(Self.ed25519Field)
            data = value
        case let .sr25519(value):
            try container.encode(Self.sr25519Field)
            data = value
        case let .ecdsa(value):
            try container.encode(Self.ecdsaField)
            data = value
        }

        let encodingList = data.map { StringScaleMapper(value: $0) }
        try container.encode(encodingList)
    }
}


extension MultiSigner: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case let .ed25519(pubKey):
            try Self.ed25519Index.encode(scaleEncoder: scaleEncoder)
            scaleEncoder.appendRaw(data: pubKey)
        case let .sr25519(pubKey):
            try Self.sr25519Index.encode(scaleEncoder: scaleEncoder)
            scaleEncoder.appendRaw(data: pubKey)
        case let .ecdsa(pubKey):
            try Self.ecdsaIndex.encode(scaleEncoder: scaleEncoder)
            scaleEncoder.appendRaw(data: pubKey)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        switch index {
        case Self.ed25519Index:
            let pubKey = try scaleDecoder.readAndConfirm(count: Self.ed25519Length)
            self = .ed25519(pubKey)
        case Self.sr25519Index:
            let pubKey = try scaleDecoder.readAndConfirm(count: Self.sr25519Length)
            self = .sr25519(pubKey)
        case Self.ecdsaIndex:
            let pubKey = try scaleDecoder.readAndConfirm(count: Self.ecdsaLength)
            self = .ecdsa(pubKey)
        default:
            throw ScaleCodingError.unexpectedDecodedValue
        }
    }
}
