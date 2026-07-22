import Foundation

public struct StorageMetadataV16 {
    public let prefix: String
    public let entries: [StorageEntryMetadataV16]

    public init(prefix: String, entries: [StorageEntryMetadataV16]) {
        self.prefix = prefix
        self.entries = entries
    }
}

extension StorageMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try prefix.encode(scaleEncoder: scaleEncoder)
        try entries.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        prefix = try String(scaleDecoder: scaleDecoder)
        entries = try [StorageEntryMetadataV16](scaleDecoder: scaleDecoder)
    }
}

public struct StorageEntryMetadataV16 {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryTypeV14
    public let defaultValue: Data
    public let documentation: [String]
    public let deprecationInfo: ItemDeprecationInfoV16

    public init(
        name: String,
        modifier: StorageEntryModifier,
        type: StorageEntryTypeV14,
        defaultValue: Data,
        documentation: [String],
        deprecationInfo: ItemDeprecationInfoV16
    ) {
        self.name = name
        self.modifier = modifier
        self.type = type
        self.defaultValue = defaultValue
        self.documentation = documentation
        self.deprecationInfo = deprecationInfo
    }
}

extension StorageEntryMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try modifier.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
        try defaultValue.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        modifier = try StorageEntryModifier(scaleDecoder: scaleDecoder)
        type = try StorageEntryTypeV14(scaleDecoder: scaleDecoder)
        defaultValue = try Data(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
        deprecationInfo = try ItemDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}
