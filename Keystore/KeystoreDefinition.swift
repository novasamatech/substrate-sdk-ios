import Foundation

public struct KeystoreDefinition: Codable {
    public let address: String
    public let encoded: String
    public let encoding: KeystoreEncoding
    public let version: String
    public let meta: KeystoreMeta

    public init(address: String,
                encoded: String,
                encoding: KeystoreEncoding,
                version: String,
                meta: KeystoreMeta) {
        self.address = address
        self.encoded = encoded
        self.encoding = encoding
        self.version = version
        self.meta = meta
    }
}

public struct KeystoreEncoding: Codable {
    public let content: [String]
    public let type: [String]

    public init(content: [String], type: [String]) {
        self.content = content
        self.type = type
    }
}

public struct KeystoreMeta: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case created = "whenCreated"
    }

    public let name: String
    public let created: Int64
}
