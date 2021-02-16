import Foundation

public struct GenericAccountIndexNode: Node {
    public var typeName: String { GenericType.accountIndex.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU32(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU32()
    }
}
