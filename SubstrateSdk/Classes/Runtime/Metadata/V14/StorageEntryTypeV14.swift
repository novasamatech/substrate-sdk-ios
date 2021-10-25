import Foundation
import BigInt

public enum StorageEntryTypeV14 {
    case plain(_ value: SiLookupId)
    case map(_ value: MapEntryV14)
}

extension StorageEntryTypeV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case .plain(let value):
            try UInt8(0).encode(scaleEncoder: scaleEncoder)
            try BigUInt(value).encode(scaleEncoder: scaleEncoder)
        case .map(let value):
            try UInt8(1).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        switch index {
        case 0:
            let type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
            self = .plain(type)
        case 1:
            let value = try MapEntryV14(scaleDecoder: scaleDecoder)
            self = .map(value)
        default:
            throw ScaleCodingError.unexpectedDecodedValue
        }
    }
}

public struct MapEntryV14 {
    public let hashers: [StorageHasher]
    public let key: SiLookupId
    public let value: SiLookupId

    public init(hashers: [StorageHasher], key: SiLookupId, value: SiLookupId) {
        self.hashers = hashers
        self.key = key
        self.value = value
    }
}

extension MapEntryV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try hashers.encode(scaleEncoder: scaleEncoder)
        try BigUInt(key).encode(scaleEncoder: scaleEncoder)
        try BigUInt(value).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        hashers = try [StorageHasher](scaleDecoder: scaleDecoder)
        key = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        value = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
