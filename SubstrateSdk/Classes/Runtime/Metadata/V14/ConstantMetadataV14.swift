import Foundation
import BigInt

public struct ConstantMetadataV14 {
    public let name: String
    public let type: SiLookupId
    public let value: Data
    public let documentation: [String]

    public init(name: String, type: SiLookupId, value: Data, documentation: [String]) {
        self.name = name
        self.type = type
        self.value = value
        self.documentation = documentation
    }
}

extension ConstantMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try value.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        value = try Data(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
