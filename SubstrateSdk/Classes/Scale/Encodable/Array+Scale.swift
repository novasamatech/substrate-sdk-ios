import Foundation
import BigInt

extension Array: ScaleEncodable where Element: ScaleEncodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(count).encode(scaleEncoder: scaleEncoder)

        for item in self {
            try item.encode(scaleEncoder: scaleEncoder)
        }
    }
}

extension Array: ScaleDecodable where Element: ScaleDecodable {
    public init(scaleDecoder: ScaleDecoding) throws {
        let count = UInt(try BigUInt(scaleDecoder: scaleDecoder))

        self = try (0 ..< count).map { _ in try Element(scaleDecoder: scaleDecoder) }
    }
}
