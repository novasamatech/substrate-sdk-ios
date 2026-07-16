import Foundation
import BigInt

public struct PalletViewFunctionMetadataV16 {
    static let idLength = 32

    /// 32 bytes id: twox128(pallet_name) ++ twox128("fn_name(arg_types) -> return_type").
    /// Passed as is to the RuntimeViewFunction_execute_view_function runtime api.
    public let id: Data
    public let name: String
    public let inputs: [RuntimeApiMethodParamMetadata]
    public let output: SiLookupId
    public let docs: [String]
    public let deprecationInfo: ItemDeprecationInfoV16

    public init(
        id: Data,
        name: String,
        inputs: [RuntimeApiMethodParamMetadata],
        output: SiLookupId,
        docs: [String],
        deprecationInfo: ItemDeprecationInfoV16
    ) {
        self.id = id
        self.name = name
        self.inputs = inputs
        self.output = output
        self.docs = docs
        self.deprecationInfo = deprecationInfo
    }
}

extension PalletViewFunctionMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        scaleEncoder.appendRaw(data: id)
        try name.encode(scaleEncoder: scaleEncoder)
        try inputs.encode(scaleEncoder: scaleEncoder)
        try BigUInt(output).encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        id = try scaleDecoder.readAndConfirm(count: Self.idLength)
        name = try String(scaleDecoder: scaleDecoder)
        inputs = try [RuntimeApiMethodParamMetadata](scaleDecoder: scaleDecoder)
        output = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        docs = try [String](scaleDecoder: scaleDecoder)
        deprecationInfo = try ItemDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}
