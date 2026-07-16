import Foundation
import BigInt

public struct PalletAssociatedTypeMetadataV16 {
    public let name: String
    public let type: SiLookupId
    public let docs: [String]

    public init(name: String, type: SiLookupId, docs: [String]) {
        self.name = name
        self.type = type
        self.docs = docs
    }
}

extension PalletAssociatedTypeMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        docs = try [String](scaleDecoder: scaleDecoder)
    }
}
