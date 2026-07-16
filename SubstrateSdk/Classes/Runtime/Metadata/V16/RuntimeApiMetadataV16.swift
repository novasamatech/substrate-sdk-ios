import Foundation
import BigInt

public struct RuntimeApiMetadataV16 {
    public let name: String
    public let methods: [RuntimeApiMethodMetadataV16]
    public let docs: [String]
    public let version: UInt32
    public let deprecationInfo: ItemDeprecationInfoV16

    public init(
        name: String,
        methods: [RuntimeApiMethodMetadataV16],
        docs: [String],
        version: UInt32,
        deprecationInfo: ItemDeprecationInfoV16
    ) {
        self.name = name
        self.methods = methods
        self.docs = docs
        self.version = version
        self.deprecationInfo = deprecationInfo
    }
}

extension RuntimeApiMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try methods.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
        try BigUInt(version).encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        methods = try [RuntimeApiMethodMetadataV16](scaleDecoder: scaleDecoder)
        docs = try [String](scaleDecoder: scaleDecoder)
        version = try UInt32(BigUInt(scaleDecoder: scaleDecoder))
        deprecationInfo = try ItemDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeApiMethodMetadataV16 {
    public let name: String
    public let inputs: [RuntimeApiMethodParamMetadata]
    public let output: SiLookupId
    public let docs: [String]
    public let deprecationInfo: ItemDeprecationInfoV16

    public init(
        name: String,
        inputs: [RuntimeApiMethodParamMetadata],
        output: SiLookupId,
        docs: [String],
        deprecationInfo: ItemDeprecationInfoV16
    ) {
        self.name = name
        self.inputs = inputs
        self.output = output
        self.docs = docs
        self.deprecationInfo = deprecationInfo
    }
}

extension RuntimeApiMethodMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try inputs.encode(scaleEncoder: scaleEncoder)
        try BigUInt(output).encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        inputs = try [RuntimeApiMethodParamMetadata](scaleDecoder: scaleDecoder)
        output = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        docs = try [String](scaleDecoder: scaleDecoder)
        deprecationInfo = try ItemDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}
