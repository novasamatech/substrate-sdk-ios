import Foundation
import NovaCrypto

public enum RawOrigin: Codable, Equatable {
    case root
    case signed(accountId: Data)
    case none

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        switch self {
        case .root:
            try container.encode("Root")
            try container.encodeNil()
        case .signed(let accountId):
            try container.encode("Signed")
            try container.encode(accountId)
        case .none:
            try container.encode("None")
            try container.encodeNil()
        }
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let type = try container.decode(String.self)

        switch type {
        case "Root":
            self = .root
        case "Signed":
            let accountId = try container.decode(Data.self)
            self = .signed(accountId: accountId)
        default:
            self = .none
        }
    }
}
