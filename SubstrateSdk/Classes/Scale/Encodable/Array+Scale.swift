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
        let bigCount = try BigUInt(scaleDecoder: scaleDecoder)

        guard bigCount <= Int.max else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        let count = Int(bigCount)

        // we should have at least `count` bytes remained otherwise the data is malicious
        guard count <= scaleDecoder.remained else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        // allocate memory only if en element is successfully decoded
        var result = [Element]()
        for _ in 0 ..< count {
            result.append(try Element(scaleDecoder: scaleDecoder))
        }
        
        self = result
    }
}
