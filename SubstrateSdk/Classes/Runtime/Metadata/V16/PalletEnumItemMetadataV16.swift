import Foundation
import BigInt

public struct CallMetadataV16 {
    public let type: SiLookupId
    public let deprecationInfo: EnumDeprecationInfoV16

    public init(type: SiLookupId, deprecationInfo: EnumDeprecationInfoV16) {
        self.type = type
        self.deprecationInfo = deprecationInfo
    }
}

extension CallMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        deprecationInfo = try EnumDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}

public struct EventMetadataV16 {
    public let type: SiLookupId
    public let deprecationInfo: EnumDeprecationInfoV16

    public init(type: SiLookupId, deprecationInfo: EnumDeprecationInfoV16) {
        self.type = type
        self.deprecationInfo = deprecationInfo
    }
}

extension EventMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        deprecationInfo = try EnumDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}

public struct ErrorMetadataV16 {
    public let type: SiLookupId
    public let deprecationInfo: EnumDeprecationInfoV16

    public init(type: SiLookupId, deprecationInfo: EnumDeprecationInfoV16) {
        self.type = type
        self.deprecationInfo = deprecationInfo
    }
}

extension ErrorMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        deprecationInfo = try EnumDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}
