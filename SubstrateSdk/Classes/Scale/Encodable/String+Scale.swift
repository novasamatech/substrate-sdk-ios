import Foundation
import BigInt

enum ScaleStringError: Error {
    case unexpectedEncoding
    case unexpectedDecoding
}

extension String: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        guard let data = data(using: .utf8) else {
            throw ScaleStringError.unexpectedEncoding
        }

        try BigUInt(data.count).encode(scaleEncoder: scaleEncoder)
        scaleEncoder.appendRaw(data: data)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let bigCount = try BigUInt(scaleDecoder: scaleDecoder)

        guard bigCount <= Int.max else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        let count = Int(bigCount)
        let data = try scaleDecoder.read(count: count)
        try scaleDecoder.confirm(count: count)

        guard let result = String(data: data, encoding: .utf8) else {
            throw ScaleStringError.unexpectedDecoding
        }

        self = result
    }
}
