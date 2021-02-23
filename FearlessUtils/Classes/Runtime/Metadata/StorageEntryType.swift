import Foundation

public enum StorageEntryType {
    case plain(_ value: String)
    case map(_ value: MapEntry)
    case doubleMap(_ value: DoubleMapEntry)

    public var typeName: String {
        switch self {
        case .plain(let value):
            return value
        case .map(let singleMap):
            return singleMap.value
        case .doubleMap(let doubleMap):
            return doubleMap.value
        }
    }
}

extension StorageEntryType: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case .plain(let value):
            try UInt8(0).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .map(let value):
            try UInt8(1).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .doubleMap(let value):
            try UInt8(2).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let rawValue = try UInt8(scaleDecoder: scaleDecoder)

        switch rawValue {
        case 0:
            let value = try String(scaleDecoder: scaleDecoder)
            self = .plain(value)
        case 1:
            let value = try MapEntry(scaleDecoder: scaleDecoder)
            self = .map(value)
        case 2:
            let value = try DoubleMapEntry(scaleDecoder: scaleDecoder)
            self = .doubleMap(value)
        default:
            throw ScaleCodingError.unexpectedDecodedValue
        }
    }
}

public struct MapEntry {
    public let hasher: StorageHasher
    public let key: String
    public let value: String
    public let unused: Bool

    public init(hasher: StorageHasher, key: String, value: String, unused: Bool) {
        self.hasher = hasher
        self.key = key
        self.value = value
        self.unused = unused
    }
}

extension MapEntry: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try hasher.encode(scaleEncoder: scaleEncoder)
        try key.encode(scaleEncoder: scaleEncoder)
        try value.encode(scaleEncoder: scaleEncoder)
        try unused.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        hasher = try StorageHasher(scaleDecoder: scaleDecoder)
        key = try String(scaleDecoder: scaleDecoder)
        value = try String(scaleDecoder: scaleDecoder)
        unused = try Bool(scaleDecoder: scaleDecoder)
    }
}

public struct DoubleMapEntry {
    public let hasher: StorageHasher
    public let key1: String
    public let key2: String
    public let value: String
    public let key2Hasher: StorageHasher

    public init(hasher: StorageHasher,
                key1: String,
                key2: String,
                value: String,
                key2Hasher: StorageHasher) {
        self.hasher = hasher
        self.key1 = key1
        self.key2 = key2
        self.value = value
        self.key2Hasher = key2Hasher
    }
}

extension DoubleMapEntry: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try hasher.encode(scaleEncoder: scaleEncoder)
        try key1.encode(scaleEncoder: scaleEncoder)
        try key2.encode(scaleEncoder: scaleEncoder)
        try value.encode(scaleEncoder: scaleEncoder)
        try key2Hasher.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        hasher = try StorageHasher(scaleDecoder: scaleDecoder)
        key1 = try String(scaleDecoder: scaleDecoder)
        key2 = try String(scaleDecoder: scaleDecoder)
        value = try String(scaleDecoder: scaleDecoder)
        key2Hasher = try StorageHasher(scaleDecoder: scaleDecoder)
    }
}

extension StorageHasher: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try rawValue.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let rawValue = try UInt8(scaleDecoder: scaleDecoder)

        guard let value = StorageHasher(rawValue: rawValue) else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        self = value
    }
}
