import Foundation

public struct KeystoreDefinition: Codable {
    public let address: String?
    public let encoded: String
    public let encoding: KeystoreEncoding
    public let meta: KeystoreMeta?

    public init(address: String?,
                encoded: String,
                encoding: KeystoreEncoding,
                meta: KeystoreMeta?) {
        self.address = address
        self.encoded = encoded
        self.encoding = encoding
        self.meta = meta
    }
}

public struct KeystoreEncoding: Codable {
    public let content: [String]
    public let type: [String]
    public let version: String

    public init(content: [String], type: [String], version: String) {
        self.content = content
        self.type = type
        self.version = version
    }
}

public struct KeystoreMeta: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case createdAt = "whenCreated"
        case genesisHash
    }

    public let name: String?
    public let createdAt: Int64?
    public let genesisHash: String?
}
