import Foundation

public struct PagedKeysRequest: Encodable {
    let key: String
    let count: UInt32
    let offset: String?
    let blockHash: Data?

    public init(
        key: String,
        count: UInt32 = 1000,
        offset: String? = nil,
        blockHash: Data? = nil
    ) {
        self.key = key
        self.count = count
        self.offset = offset
        self.blockHash = blockHash
    }

    // state_getKeysPaged params are positional: prefix, count, start_key, at.
    // Absent values must be encoded as null, otherwise a block hash shifts into start_key.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(key)
        try container.encode(count)
        try container.encode(offset)
        try container.encode(blockHash?.toHex(includePrefix: true))
    }
}
