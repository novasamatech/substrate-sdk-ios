import Foundation
import BigInt

public struct ExtrinsicMetadataV15 {
    public let version: UInt8
    public let addressType: SiLookupId
    public let callType: SiLookupId
    public let signatureType: SiLookupId
    public let extraType: SiLookupId
    public let signedExtensions: [SignedExtensionV14]

    public init(
        version: UInt8,
        addressType: SiLookupId,
        callType: SiLookupId,
        signatureType: SiLookupId,
        extraType: SiLookupId,
        signedExtensions: [SignedExtensionV14]
    ) {
        self.version = version
        self.addressType = addressType
        self.callType = callType
        self.signatureType = signatureType
        self.extraType = extraType
        self.signedExtensions = signedExtensions
    }
}

extension ExtrinsicMetadataV15: PostV14ExtrinsicMetadataProtocol {}

extension ExtrinsicMetadataV15: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try version.encode(scaleEncoder: scaleEncoder)
        try BigUInt(addressType).encode(scaleEncoder: scaleEncoder)
        try BigUInt(callType).encode(scaleEncoder: scaleEncoder)
        try BigUInt(signatureType).encode(scaleEncoder: scaleEncoder)
        try BigUInt(extraType).encode(scaleEncoder: scaleEncoder)
        try signedExtensions.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        version = try UInt8(scaleDecoder: scaleDecoder)
        addressType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        callType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        signatureType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        extraType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        signedExtensions = try [SignedExtensionV14](scaleDecoder: scaleDecoder)
    }
}
