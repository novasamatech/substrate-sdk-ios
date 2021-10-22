import Foundation

public struct StorageMetadata {
    public let prefix: String
    public let entries: [StorageEntryMetadata]

    public init(prefix: String, entries: [StorageEntryMetadata]) {
        self.prefix = prefix
        self.entries = entries
    }
}

extension StorageMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try prefix.encode(scaleEncoder: scaleEncoder)
        try entries.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        prefix = try String(scaleDecoder: scaleDecoder)
        entries = try [StorageEntryMetadata](scaleDecoder: scaleDecoder)
    }
}
