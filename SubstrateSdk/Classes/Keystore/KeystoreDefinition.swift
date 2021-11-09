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
    enum CodingKeys: String, CodingKey {
        case content
        case type
        case version
    }

    public let content: [String]
    public let type: [String]
    public let version: String

    public init(content: [String], type: [String], version: String) {
        self.content = content
        self.type = type
        self.version = version
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        content = try container.decode([String].self, forKey: .content)
        type = try container.decode([String].self, forKey: .type)

        if let stringVersion = try? container.decode(String.self, forKey: .version) {
            version = stringVersion
        } else if let intVersion = try? container.decode(Int.self, forKey: .version) {
            version = String(intVersion)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: container,
                debugDescription: "Unexpected value type"
            )
        }
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
