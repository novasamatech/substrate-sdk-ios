import Foundation
import BigInt

public struct ErrorMetadataV14 {
    public let type: SiLookupId

    public init(type: SiLookupId) {
        self.type = type
    }
}

extension ErrorMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
