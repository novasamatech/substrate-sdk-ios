import Foundation
import BigInt

public struct RuntimeApiMetadata {
    public let name: String
    public let methods: [RuntimeApiMethodMetadata]
    public let docs: [String]
}

extension RuntimeApiMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try methods.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        methods = try [RuntimeApiMethodMetadata](scaleDecoder: scaleDecoder)
        docs = try [String](scaleDecoder: scaleDecoder)
    }
}
