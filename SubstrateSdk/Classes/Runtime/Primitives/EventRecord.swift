import Foundation

public struct EventRecord: Decodable {
    public enum CodingKeys: String, CodingKey {
        case phase
        case event
    }

    public let phase: Phase
    public let event: Event

    public init(from decoder: Decoder) throws {
        if let keyedContainer = try? decoder.container(keyedBy: CodingKeys.self) {
            phase = try keyedContainer.decode(Phase.self, forKey: .phase)
            event = try keyedContainer.decode(Event.self, forKey: .event)
        } else {
            var unkeyedContainer = try decoder.unkeyedContainer()
            phase = try unkeyedContainer.decode(Phase.self)
            event = try unkeyedContainer.decode(Event.self)
        }
    }
}

public extension EventRecord {
    var extrinsicIndex: UInt32? {
        if case let .applyExtrinsic(index) = phase {
            return index
        } else {
            return nil
        }
    }
}
