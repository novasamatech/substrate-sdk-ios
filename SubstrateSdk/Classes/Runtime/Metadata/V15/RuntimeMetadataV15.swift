import Foundation
import BigInt

public struct RuntimeMetadataV15 {
    public let types: RuntimeTypesLookup
    public let pallets: [PalletMetadataV15]
    public let extrinsic: ExtrinsicMetadataV15
    public let runtimeType: SiLookupId
    public let apis: [RuntimeApiMetadata]

    public init(
        types: RuntimeTypesLookup,
        pallets: [PalletMetadataV15],
        extrinsic: ExtrinsicMetadataV15,
        runtimeType: SiLookupId,
        apis: [RuntimeApiMetadata]
    ) {
        self.types = types
        self.pallets = pallets
        self.extrinsic = extrinsic
        self.runtimeType = runtimeType
        self.apis = apis
    }
}

extension RuntimeMetadataV15: PostV14RuntimeMetadataProtocol {
    public var postV14Pallets: [PostV14PalletMetadataProtocol] {
        pallets
    }

    public var postV14Extrinsic: PostV14ExtrinsicMetadataProtocol {
        extrinsic
    }
    
    public func getRuntimeApiMethod(for runtimeApiName: String, methodName: String) -> RuntimeApiQueryResult? {
        guard let api = apis.first(where: { $0.name == runtimeApiName }) else {
            return nil
        }
        
        guard let method = api.methods.first(where: { $0.name == methodName }) else {
            return nil
        }
        
        return .init(callName: runtimeApiName + "_" + methodName, method: method)
    }
}

extension RuntimeMetadataV15: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try types.encode(scaleEncoder: scaleEncoder)
        try pallets.encode(scaleEncoder: scaleEncoder)
        try extrinsic.encode(scaleEncoder: scaleEncoder)
        try BigUInt(runtimeType).encode(scaleEncoder: scaleEncoder)
        try apis.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        types = try RuntimeTypesLookup(scaleDecoder: scaleDecoder)
        pallets = try [PalletMetadataV15](scaleDecoder: scaleDecoder)
        extrinsic = try ExtrinsicMetadataV15(scaleDecoder: scaleDecoder)
        runtimeType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        apis = try [RuntimeApiMetadata](scaleDecoder: scaleDecoder)
    }
}
