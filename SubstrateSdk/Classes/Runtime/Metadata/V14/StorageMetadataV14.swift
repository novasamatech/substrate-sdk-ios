import Foundation

public struct StorageMetadataV14 {
    public let prefix: String
    public let entries: [StorageEntryMetadataV14]

    public init(prefix: String, entries: [StorageEntryMetadataV14]) {
        self.prefix = prefix
        self.entries = entries
    }
}

extension StorageMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try prefix.encode(scaleEncoder: scaleEncoder)
        try entries.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        prefix = try String(scaleDecoder: scaleDecoder)
        entries = try [StorageEntryMetadataV14](scaleDecoder: scaleDecoder)
    }
}
