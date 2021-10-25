import Foundation
import BigInt

public struct ExtrinsicMetadataV14 {
    public let type: SiLookupId
    public let version: UInt8
    public let signedExtensions: [SignedExtensionV14]

    public init(type: SiLookupId, version: UInt8, signedExtensions: [SignedExtensionV14]) {
        self.type = type
        self.version = version
        self.signedExtensions = signedExtensions
    }
}

extension ExtrinsicMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try version.encode(scaleEncoder: scaleEncoder)
        try signedExtensions.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        version = try UInt8(scaleDecoder: scaleDecoder)
        signedExtensions = try [SignedExtensionV14](scaleDecoder: scaleDecoder)
    }
}

public struct SignedExtensionV14 {
    public let identifier: String
    public let type: SiLookupId
    public let additionalSigned: SiLookupId

    public init(identifier: String, type: SiLookupId, additionalSigned: SiLookupId) {
        self.identifier = identifier
        self.type = type
        self.additionalSigned = additionalSigned
    }
}

extension SignedExtensionV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try identifier.encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try BigUInt(additionalSigned).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        identifier = try String(scaleDecoder: scaleDecoder)
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        additionalSigned = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
