import Foundation

@dynamicMemberLookup
public enum JSON {
    case unsignedIntValue(UInt64)
    case signedIntValue(Int64)
    case stringValue(String)
    case arrayValue([JSON])
    case dictionaryValue([String: JSON])
    case boolValue(Bool)
    case null

    public var stringValue: String? {
        if case .stringValue(let str) = self {
            return str
        }
        return nil
    }

    public var arrayValue: [JSON]? {
        if case .arrayValue(let value) = self {
            return value
        }

        return nil
    }

    public var dictValue: [String: JSON]? {
        if case .dictionaryValue(let value) = self {
            return value
        }

        return nil
    }

    public var unsignedIntValue: UInt64? {
        if case .unsignedIntValue(let value) = self {
            return value
        }

        return nil
    }

    public var signedIntValue: Int64? {
        if case .signedIntValue(let value) = self {
            return value
        }

        return nil
    }

    public var boolValue: Bool? {
        if case .boolValue(let value) = self {
            return value
        }

        return nil
    }

    public var isNull: Bool {
        if case .null = self {
            return true
        } else {
            return false
        }
    }

    public subscript(index: Int) -> JSON? {
        if let arr = arrayValue {
            return index < arr.count ? arr[index] : nil
        }
        return nil
    }

    public subscript(key: String) -> JSON? {
        if let dict = dictValue {
            return dict[key]
        }
        return nil
    }

    public subscript(dynamicMember member: String) -> JSON? {
        if let dict = dictValue {
            return dict[member]
        }
        return nil
    }
}

public enum JSONError: Error {
    case unsupported
}

extension JSON: Codable {
    public init(from decoder: Decoder) throws {
        if let unsignedIntValue = try? UInt64(from: decoder) {
            self = .unsignedIntValue(unsignedIntValue)
        } else if let signedIntValue = try? Int64(from: decoder) {
            self = .signedIntValue(signedIntValue)
        } else if let boolValue = try? Bool(from: decoder) {
            self = .boolValue(boolValue)
        } else if let stringValue = try? String(from: decoder) {
            self = .stringValue(stringValue)
        } else if let node = try? [String: JSON](from: decoder) {
            self = .dictionaryValue(node)
        } else if let list = try? [JSON](from: decoder) {
            self = .arrayValue(list)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .unsignedIntValue(let value):
            try value.encode(to: encoder)
        case .signedIntValue(let value):
            try value.encode(to: encoder)
        case .boolValue(let value):
            try value.encode(to: encoder)
        case .stringValue(let value):
            try value.encode(to: encoder)
        case .dictionaryValue(let value):
            try value.encode(to: encoder)
        case .arrayValue(let value):
            try value.encode(to: encoder)
        case .null:
            try (JSON?).none.encode(to: encoder)
        }
    }
}

extension JSON: Equatable {}
