import Foundation

/// JSON-RPC request id preserving the wire type. The engine allocates its own
/// numeric ids internally; this type serves adapters that relay someone else's
/// id space (e.g. an embedded client whose frames must round-trip verbatim).
public enum JSONRPCId: Codable, Hashable {
    case number(UInt64)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            self = try .number(container.decode(UInt64.self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .number(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        }
    }
}

/// Outgoing request or notification: a nil id encodes as an absent member,
/// which per JSON-RPC 2.0 marks the frame as a notification.
public struct JSONRPCRequestEnvelope<P: Codable>: Codable {
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }

    public let jsonrpc: String
    public let id: JSONRPCId?
    public let method: String
    public let params: P?

    public init(id: JSONRPCId?, method: String, params: P?) {
        jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JSONRPCResponseEnvelope<R: Codable>: Codable {
    public let jsonrpc: String
    public let id: JSONRPCId
    public let result: R

    public init(id: JSONRPCId, result: R) {
        jsonrpc = "2.0"
        self.id = id
        self.result = result
    }
}

/// Error response: per JSON-RPC 2.0 the id member is required, so a nil id
/// (request id undetectable) encodes as an explicit null.
public struct JSONRPCErrorEnvelope: Codable {
    enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case error
    }

    public let jsonrpc: String
    public let id: JSONRPCId?
    public let error: JSONRPCError

    public init(id: JSONRPCId?, error: JSONRPCError) {
        jsonrpc = "2.0"
        self.id = id
        self.error = error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(error, forKey: .error)

        if let id {
            try container.encode(id, forKey: .id)
        } else {
            try container.encodeNil(forKey: .id)
        }
    }
}

public struct JSONRPCSubscriptionParams<R: Codable>: Codable {
    public let subscription: JSONRPCSubscriptionId
    public let result: R

    public init(subscription: JSONRPCSubscriptionId, result: R) {
        self.subscription = subscription
        self.result = result
    }
}

/// Server-pushed subscription notification.
public struct JSONRPCNotificationEnvelope<R: Codable>: Codable {
    public let jsonrpc: String
    public let method: String
    public let params: JSONRPCSubscriptionParams<R>

    public init(method: String, params: JSONRPCSubscriptionParams<R>) {
        jsonrpc = "2.0"
        self.method = method
        self.params = params
    }
}
