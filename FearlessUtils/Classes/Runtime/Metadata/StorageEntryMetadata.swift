import Foundation

public struct StorageEntryMetadata {
    public let name: String
    public let modifier: StorageEntryModifier
    public let type: StorageEntryType
    public let defaultValue: Data
    public let documentation: [String]

    public init(name: String,
                modifier: StorageEntryModifier,
                type: StorageEntryType,
                defaultValue: Data,
                documentation: [String]) {
        self.name = name
        self.modifier = modifier
        self.type = type
        self.defaultValue = defaultValue
        self.documentation = documentation
    }
}

extension StorageEntryMetadata: ScaleCodable {
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
        type = try StorageEntryType(scaleDecoder: scaleDecoder)
        defaultValue = try Data(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
