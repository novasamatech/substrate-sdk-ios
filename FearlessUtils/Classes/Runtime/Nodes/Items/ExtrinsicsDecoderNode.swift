import Foundation

public struct ExtrinsicsDecoderNode: Node {
    public var typeName: String { GenericType.extrinsicDecoder.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {}

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON { .null }
}
