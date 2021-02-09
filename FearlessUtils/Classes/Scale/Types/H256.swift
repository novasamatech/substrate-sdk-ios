import Foundation

public struct H256: ScaleCodable, Equatable {
    public let value: Data

    public init(value: Data) {
        self.value = value
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        value = try scaleDecoder.readAndConfirm(count: 32)
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        scaleEncoder.appendRaw(data: value)
    }
}
