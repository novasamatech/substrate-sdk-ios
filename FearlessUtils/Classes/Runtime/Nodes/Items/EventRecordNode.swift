import Foundation

public struct EventRecordNode: Node {
    public var typeName: String { "EventRecord" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {

    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        .null
    }
}
