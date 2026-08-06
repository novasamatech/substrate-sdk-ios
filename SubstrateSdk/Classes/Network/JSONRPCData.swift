import Foundation

public struct JSONRPCError: Error, Codable {
    enum CodingKeys: String, CodingKey {
        case message
        case code
        case data
    }

    public let message: String
    public let code: Int
    public let data: String?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        message = try container.decode(String.self, forKey: .message)
        code = try container.decode(Int.self, forKey: .code)
        data = try? container.decode(String.self, forKey: .data)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(message, forKey: .message)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(data, forKey: .data)
    }

    public init(message: String, code: Int, data: String?) {
        self.message = message
        self.code = code
        self.data = data
    }
}

struct JSONRPCData<T: Decodable>: Decodable {
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case result
        case error
        case identifier = "id"
    }

    let jsonrpc: String
    let result: T
    let error: JSONRPCError?
    let identifier: UInt16
}

public struct JSONRPCSubscriptionUpdate<T: Decodable>: Decodable {
    public struct Result: Decodable {
        public let result: T
        public let subscription: JSONRPCSubscriptionId

        public init(result: T, subscription: JSONRPCSubscriptionId) {
            self.result = result
            self.subscription = subscription
        }
    }

    public let jsonrpc: String
    public let method: String
    public let params: Result

    public init(jsonrpc: String, method: String, params: Result) {
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
    }
}

struct JSONRPCSubscriptionBasicUpdate: Decodable {
    struct Result: Decodable {
        let subscription: JSONRPCSubscriptionId
    }

    let jsonrpc: String
    let method: String
    let params: Result
}

struct JSONRPCBasicData: Decodable {
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case error
        case identifier = "id"
    }

    let jsonrpc: String
    let error: JSONRPCError?
    let identifier: UInt16?
}
