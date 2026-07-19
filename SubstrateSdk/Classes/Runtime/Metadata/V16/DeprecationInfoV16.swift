import Foundation

public enum ItemDeprecationInfoV16 {
    case notDeprecated
    case deprecatedWithoutNote
    case deprecated(note: String, since: String?)
}

extension ItemDeprecationInfoV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case .notDeprecated:
            try UInt8(0).encode(scaleEncoder: scaleEncoder)
        case .deprecatedWithoutNote:
            try UInt8(1).encode(scaleEncoder: scaleEncoder)
        case let .deprecated(note, since):
            try UInt8(2).encode(scaleEncoder: scaleEncoder)
            try note.encode(scaleEncoder: scaleEncoder)
            try ScaleOption(value: since).encode(scaleEncoder: scaleEncoder)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        switch index {
        case 0:
            self = .notDeprecated
        case 1:
            self = .deprecatedWithoutNote
        case 2:
            let note = try String(scaleDecoder: scaleDecoder)
            let since = try ScaleOption<String>(scaleDecoder: scaleDecoder).value
            self = .deprecated(note: note, since: since)
        default:
            throw ScaleCodingError.unexpectedDecodedValue
        }
    }
}

public enum VariantDeprecationInfoV16 {
    case deprecatedWithoutNote
    case deprecated(note: String, since: String?)
}

extension VariantDeprecationInfoV16: ScaleCodable {
    // variant indexes start from 1 to align with ItemDeprecationInfoV16
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case .deprecatedWithoutNote:
            try UInt8(1).encode(scaleEncoder: scaleEncoder)
        case let .deprecated(note, since):
            try UInt8(2).encode(scaleEncoder: scaleEncoder)
            try note.encode(scaleEncoder: scaleEncoder)
            try ScaleOption(value: since).encode(scaleEncoder: scaleEncoder)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        switch index {
        case 1:
            self = .deprecatedWithoutNote
        case 2:
            let note = try String(scaleDecoder: scaleDecoder)
            let since = try ScaleOption<String>(scaleDecoder: scaleDecoder).value
            self = .deprecated(note: note, since: since)
        default:
            throw ScaleCodingError.unexpectedDecodedValue
        }
    }
}

public struct EnumDeprecationInfoV16 {
    public struct Entry {
        public let variantIndex: UInt8
        public let deprecationInfo: VariantDeprecationInfoV16

        public init(variantIndex: UInt8, deprecationInfo: VariantDeprecationInfoV16) {
            self.variantIndex = variantIndex
            self.deprecationInfo = deprecationInfo
        }
    }

    public let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }
}

extension EnumDeprecationInfoV16.Entry: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try variantIndex.encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        variantIndex = try UInt8(scaleDecoder: scaleDecoder)
        deprecationInfo = try VariantDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}

extension EnumDeprecationInfoV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try entries.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        entries = try [Entry](scaleDecoder: scaleDecoder)
    }
}
