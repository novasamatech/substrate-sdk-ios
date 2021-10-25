import Foundation

public struct ScaleTuple<T1: ScaleCodable, T2: ScaleCodable>: ScaleCodable {
    public let first: T1
    public let second: T2

    public init(first: T1, second: T2) {
        self.first = first
        self.second = second
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        first = try T1(scaleDecoder: scaleDecoder)
        second = try T2(scaleDecoder: scaleDecoder)
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        try first.encode(scaleEncoder: scaleEncoder)
        try second.encode(scaleEncoder: scaleEncoder)
    }
}
