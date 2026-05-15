import Foundation
import BigInt

extension Data: ScaleCodable {
    public init(scaleDecoder: ScaleDecoding) throws {
        let bigCount = try BigUInt(scaleDecoder: scaleDecoder)

        guard bigCount <= Int.max else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        let count = Int(bigCount)
        self = try scaleDecoder.readAndConfirm(count: count)
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(count).encode(scaleEncoder: scaleEncoder)
        scaleEncoder.appendRaw(data: self)
    }
}

public extension Data {
    func toScaleByteArray() -> [StringScaleMapper<UInt8>] {
        map { StringScaleMapper(value: $0) }
    }

    init(scaleByteArray: [StringScaleMapper<UInt8>]) {
        self.init(scaleByteArray.map(\.value))
    }
}
