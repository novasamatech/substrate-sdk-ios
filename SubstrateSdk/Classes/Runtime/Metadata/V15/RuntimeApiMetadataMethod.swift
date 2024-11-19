import Foundation
import BigInt

public struct RuntimeApiMethodMetadata {
    public let name: String
    public let inputs: [RuntimeApiMethodParamMetadata]
    public let output: SiLookupId
    public let docs: [String]
}

extension RuntimeApiMethodMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try inputs.encode(scaleEncoder: scaleEncoder)
        try BigUInt(output).encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        inputs = try [RuntimeApiMethodParamMetadata](scaleDecoder: scaleDecoder)
        output = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        docs = try [String](scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeApiMethodParamMetadata {
    public let name: String
    public let paramType: SiLookupId
}

extension RuntimeApiMethodParamMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try BigUInt(paramType).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        paramType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
