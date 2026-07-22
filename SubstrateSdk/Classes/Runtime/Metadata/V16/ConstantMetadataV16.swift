import Foundation
import BigInt

public struct ConstantMetadataV16 {
    public let name: String
    public let type: SiLookupId
    public let value: Data
    public let documentation: [String]
    public let deprecationInfo: ItemDeprecationInfoV16

    public init(
        name: String,
        type: SiLookupId,
        value: Data,
        documentation: [String],
        deprecationInfo: ItemDeprecationInfoV16
    ) {
        self.name = name
        self.type = type
        self.value = value
        self.documentation = documentation
        self.deprecationInfo = deprecationInfo
    }
}

extension ConstantMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try value.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        value = try Data(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
        deprecationInfo = try ItemDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}
