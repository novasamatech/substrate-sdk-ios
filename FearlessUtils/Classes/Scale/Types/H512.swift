import Foundation

public struct H512: ScaleCodable, Equatable {
    public let value: Data

    public init(scaleDecoder: ScaleDecoding) throws {
        value = try scaleDecoder.readAndConfirm(count: 64)
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        scaleEncoder.appendRaw(data: value)
    }
}
