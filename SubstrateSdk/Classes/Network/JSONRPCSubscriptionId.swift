import Foundation

/// Node-assigned subscription id preserving the wire type. jsonrpsee servers key
/// subscriptions by an untagged number-or-string value, so unsubscribe calls must
/// echo the id exactly as assigned — a stringified number never matches a numeric key.
public enum JSONRPCSubscriptionId: Codable, Hashable {
    case number(UInt64)
    case string(String)

    /// Canonical textual form for logging and string-keyed consumers.
    public var stringValue: String {
        switch self {
        case let .number(value):
            String(value)
        case let .string(value):
            value
        }
    }

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

extension JSONRPCSubscriptionId: CustomStringConvertible {
    public var description: String { stringValue }
}

extension JSONRPCSubscriptionId: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
