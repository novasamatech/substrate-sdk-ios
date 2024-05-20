import Foundation
import BigInt

struct RuntimeMetadataV15 {
    public let types: RuntimeTypesLookup
    public let pallets: [PalletMetadataV15]
    public let extrinsic: ExtrinsicMetadataV15
    public let runtimeType: SiLookupId
    
    public init(
        types: RuntimeTypesLookup,
        pallets: [PalletMetadataV15],
        extrinsic: ExtrinsicMetadataV15,
        runtimeType: SiLookupId
    ) {
        self.types = types
        self.pallets = pallets
        self.extrinsic = extrinsic
        self.runtimeType = runtimeType
    }
}

extension RuntimeMetadataV15: PostV14RuntimeMetadataProtocol {
    public var postV14Pallets: [PostV14PalletMetadataProtocol] {
        pallets
    }
    
    public var postV14Extrinsic: PostV14ExtrinsicMetadataProtocol {
        extrinsic
    }
}

extension RuntimeMetadataV15: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try types.encode(scaleEncoder: scaleEncoder)
        try pallets.encode(scaleEncoder: scaleEncoder)
        try extrinsic.encode(scaleEncoder: scaleEncoder)
        try BigUInt(runtimeType).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        types = try RuntimeTypesLookup(scaleDecoder: scaleDecoder)
        pallets = try [PalletMetadataV15](scaleDecoder: scaleDecoder)
        extrinsic = try ExtrinsicMetadataV15(scaleDecoder: scaleDecoder)
        runtimeType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
