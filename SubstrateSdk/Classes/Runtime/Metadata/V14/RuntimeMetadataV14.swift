import Foundation
import BigInt

public struct RuntimeMetadataV14 {
    public let types: RuntimeTypesLookup
    public let pallets: [PalletMetadataV14]
    public let extrinsic: ExtrinsicMetadataV14
    public let runtimeType: SiLookupId

    public init(
        types: RuntimeTypesLookup,
        pallets: [PalletMetadataV14],
        extrinsic: ExtrinsicMetadataV14,
        runtimeType: SiLookupId
    ) {
        self.types = types
        self.pallets = pallets
        self.extrinsic = extrinsic
        self.runtimeType = runtimeType
    }
}

extension RuntimeMetadataV14: PostV14RuntimeMetadataProtocol {
    public var postV14Pallets: [PostV14PalletMetadataProtocol] {
        pallets
    }

    public var postV14Extrinsic: PostV14ExtrinsicMetadataProtocol {
        extrinsic
    }

    public func getRuntimeApiMethod(for _: String, methodName _: String) -> RuntimeApiQueryResult? {
        nil
    }
}

extension RuntimeMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try types.encode(scaleEncoder: scaleEncoder)
        try pallets.encode(scaleEncoder: scaleEncoder)
        try extrinsic.encode(scaleEncoder: scaleEncoder)
        try BigUInt(runtimeType).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        types = try RuntimeTypesLookup(scaleDecoder: scaleDecoder)
        pallets = try [PalletMetadataV14](scaleDecoder: scaleDecoder)
        extrinsic = try ExtrinsicMetadataV14(scaleDecoder: scaleDecoder)
        runtimeType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
