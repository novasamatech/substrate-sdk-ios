import Foundation
import BigInt

public enum MultiAddress: Equatable {
    static let accountIdField = "Id"
    static let indexField = "Index"
    static let rawField = "Raw"
    static let address32Field = "Address32"
    static let address20Field = "Address20"

    case accoundId(_ value: Data)
    case accountIndex(_ value: BigUInt)
    case raw(_ value: Data)
    case address32(_ value: Data)
    case address20(_ value: Data)

    public var accountId: Data? {
        switch self {
        case .accoundId(let value):
            return value
        case .accountIndex, .raw, .address32, .address20:
            return nil
        }
    }
}

extension MultiAddress: Codable {
    public init(from decoder: Decoder) throws {
        let context = RuntimeJsonContext(rawContext: decoder.userInfo)

        if context.prefersRawAddress {
            self = try Self.decodeAccountId(from: decoder)
        } else {
            self = try Self.decodeMultiAddress(from: decoder)
        }
    }

    public func encode(to encoder: Encoder) throws {
        let context = RuntimeJsonContext(rawContext: encoder.userInfo)

        if
            context.prefersRawAddress,
            let accountId = self.accountId {
            try encodeAccountId(accountId, to: encoder)
        } else {
            try encodeMultiAddress(to: encoder)
        }
    }

    private static func decodeAccountId(from decoder: Decoder) throws -> MultiAddress {
        let container = try decoder.singleValueContainer()

        if let accountId = try? container.decode(Data.self) {
            return .accoundId(accountId)
        } else {
            let byteArray = try container.decode([StringScaleMapper<UInt8>].self)
            let accountId = Data(scaleByteArray: byteArray)

            return .accoundId(accountId)
        }
    }

    private static func decodeMultiAddress(from decoder: Decoder) throws -> MultiAddress {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(String.self)

        switch type {
        case Self.accountIdField:
            let data = try decodeMultiAddressData(from: &container)
            return .accoundId(data)
        case Self.indexField:
            let intStr = try container.decode(String.self)
            guard let value = BigUInt(intStr) else {
                throw DecodingError.dataCorruptedError(in: container,
                                                       debugDescription: "Unexpected big int value")
            }

            return .accountIndex(value)
        case Self.rawField:
            let data = try decodeMultiAddressData(from: &container)
            return .raw(data)
        case Self.address32Field:
            let data = try decodeMultiAddressData(from: &container)
            return .address32(data)
        case Self.address20Field:
            let data = try decodeMultiAddressData(from: &container)
            return .address20(data)
        default:
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unexpected type")
        }
    }

    private static func decodeMultiAddressData(from container: inout UnkeyedDecodingContainer) throws -> Data {
        if let data = try? container.decode(Data.self) {
            return data
        } else {
            let byteArray = try container.decode([StringScaleMapper<UInt8>].self)
            let data = Data(scaleByteArray: byteArray)

            return data
        }
    }

    private func encodeAccountId(_ accountId: Data, to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(accountId)
    }

    private func encodeMultiAddress(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        switch self {
        case .accoundId(let value):
            try container.encode(Self.accountIdField)
            try container.encode(value)
        case .accountIndex(let value):
            try container.encode(Self.indexField)
            try container.encode(String(value))
        case .raw(let value):
            try container.encode(Self.rawField)
            try container.encode(value)
        case .address32(let value):
            try container.encode(Self.address32Field)
            try container.encode(value)
        case .address20(let value):
            try container.encode(Self.address20Field)
            try container.encode(value)
        }
    }
}
