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

    public var supportedFormatVersions: [UInt8]? {
        versions
    }

    public var supportedExtensionVersions: [UInt8] {
        transactionExtensionsByVersion.map(\.extensionVersion)
    }

    public func signedExtensions(forExtensionVersion version: UInt8) throws -> [SignedExtensionV14] {
        guard let entry = transactionExtensionsByVersion.first(where: { $0.extensionVersion == version }) else {
            throw PostV14ExtrinsicMetadataError.unsupportedExtensionVersion(version)
        }

        return try entry.extensionIndexes.map { index in
            guard Int(index) < transactionExtensions.count else {
                throw PostV14ExtrinsicMetadataError.invalidExtensionIndex(index)
            }

            let ext = transactionExtensions[Int(index)]

            return SignedExtensionV14(
                identifier: ext.identifier,
                type: ext.type,
                additionalSigned: ext.implicit
            )
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

/// An entry of the BTreeMap<u8, Vec<Compact<u32>>> mapping a supported *transaction
/// extension* version (the byte a v5/general extrinsic encodes after the format byte)
/// to the indexes of the transaction extensions used by that version.
public struct TransactionExtensionsVersionV16 {
    public let extensionVersion: UInt8
    public let extensionIndexes: [UInt32]

    public init(extensionVersion: UInt8, extensionIndexes: [UInt32]) {
        self.extensionVersion = extensionVersion
        self.extensionIndexes = extensionIndexes
    }
}

extension TransactionExtensionsVersionV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try extensionVersion.encode(scaleEncoder: scaleEncoder)
        try extensionIndexes.map { BigUInt($0) }.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        extensionVersion = try UInt8(scaleDecoder: scaleDecoder)
        extensionIndexes = try [BigUInt](scaleDecoder: scaleDecoder).map { index in
            guard let value = UInt32(exactly: index) else {
                throw ScaleCodingError.unexpectedDecodedValue
            }

            return value
        }
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
