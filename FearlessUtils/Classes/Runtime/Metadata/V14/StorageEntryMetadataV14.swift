import Foundation

public struct StorageEntryMetadataV14 {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryTypeV14
    public let defaultValue: Data
    public let documentation: [String]

    public init(
        name: String,
        modifier: StorageEntryModifier,
        type: StorageEntryTypeV14,
        defaultValue: Data,
        documentation: [String]
    ) {
        self.name = name
        self.modifier = modifier
        self.type = type
        self.defaultValue = defaultValue
        self.documentation = documentation
    }
}

extension StorageEntryMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try modifier.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
        try defaultValue.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        modifier = try StorageEntryModifier(scaleDecoder: scaleDecoder)
        type = try StorageEntryTypeV14(scaleDecoder: scaleDecoder)
        defaultValue = try Data(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
