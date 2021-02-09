import Foundation

public struct H160: ScaleCodable, Equatable {
    public let value: Data

    public init(scaleDecoder: ScaleDecoding) throws {
        value = try scaleDecoder.readAndConfirm(count: 20)
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        scaleEncoder.appendRaw(data: value)
    }
}
