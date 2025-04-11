import Foundation

public class GenericBlockNode: Node {
    public var typeName: String { GenericType.block.name }

    public init() {}

    public func accept(encoder _: DynamicScaleEncoding, value _: JSON) throws {
        throw DynamicScaleCoderError.unresolverType(name: typeName)
    }

    public func accept(decoder _: DynamicScaleDecoding) throws -> JSON {
        throw DynamicScaleCoderError.unresolverType(name: typeName)
    }
}
