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

        try data.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let data = try Data(scaleDecoder: scaleDecoder)

        guard let result = String(data: data, encoding: .utf8) else {
            throw ScaleStringError.unexpectedDecoding
        }

        self = result
    }
}
