import Foundation
import BigInt

public struct ExtrinsicMetadataV16 {
    public let versions: [UInt8]
    public let addressType: SiLookupId
    public let callType: SiLookupId
    public let signatureType: SiLookupId
    public let transactionExtensionsByVersion: [TransactionExtensionsVersionV16]
    public let transactionExtensions: [TransactionExtensionMetadataV16]

    public init(
        versions: [UInt8],
        addressType: SiLookupId,
        callType: SiLookupId,
        signatureType: SiLookupId,
        transactionExtensionsByVersion: [TransactionExtensionsVersionV16],
        transactionExtensions: [TransactionExtensionMetadataV16]
    ) {
        self.versions = versions
        self.addressType = addressType
        self.callType = callType
        self.signatureType = signatureType
        self.transactionExtensionsByVersion = transactionExtensionsByVersion
        self.transactionExtensions = transactionExtensions
    }
}

extension ExtrinsicMetadataV16: PostV14ExtrinsicMetadataProtocol {
    public var signedExtensions: [SignedExtensionV14] {
        transactionExtensions.map {
            SignedExtensionV14(identifier: $0.identifier, type: $0.type, additionalSigned: $0.implicit)
        }
    }
}

extension ExtrinsicMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try versions.encode(scaleEncoder: scaleEncoder)
        try BigUInt(addressType).encode(scaleEncoder: scaleEncoder)
        try BigUInt(callType).encode(scaleEncoder: scaleEncoder)
        try BigUInt(signatureType).encode(scaleEncoder: scaleEncoder)
        try transactionExtensionsByVersion.encode(scaleEncoder: scaleEncoder)
        try transactionExtensions.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        versions = try [UInt8](scaleDecoder: scaleDecoder)
        addressType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        callType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        signatureType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        transactionExtensionsByVersion = try [TransactionExtensionsVersionV16](scaleDecoder: scaleDecoder)
        transactionExtensions = try [TransactionExtensionMetadataV16](scaleDecoder: scaleDecoder)
    }
}

/// An entry of the BTreeMap<u8, Vec<Compact<u32>>> mapping a supported extrinsic
/// version to the indexes of the transaction extensions used by that version.
public struct TransactionExtensionsVersionV16 {
    public let version: UInt8
    public let extensionIndexes: [UInt32]

    public init(version: UInt8, extensionIndexes: [UInt32]) {
        self.version = version
        self.extensionIndexes = extensionIndexes
    }
}

extension TransactionExtensionsVersionV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try version.encode(scaleEncoder: scaleEncoder)
        try extensionIndexes.map { BigUInt($0) }.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        version = try UInt8(scaleDecoder: scaleDecoder)
        extensionIndexes = try [BigUInt](scaleDecoder: scaleDecoder).map { UInt32($0) }
    }
}

public struct TransactionExtensionMetadataV16 {
    public let identifier: String
    public let type: SiLookupId
    public let implicit: SiLookupId

    public init(identifier: String, type: SiLookupId, implicit: SiLookupId) {
        self.identifier = identifier
        self.type = type
        self.implicit = implicit
    }
}

extension TransactionExtensionMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try identifier.encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try BigUInt(implicit).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        identifier = try String(scaleDecoder: scaleDecoder)
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        implicit = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
