import Foundation

public enum PostV14ExtrinsicMetadataError: Error, Equatable {
    case unsupportedFormatVersion(UInt8)
    case unsupportedExtensionVersion(UInt8)
    case invalidExtensionIndex(UInt32)
}

public protocol PostV14ExtrinsicMetadataProtocol {
    var signedExtensions: [SignedExtensionV14] { get }
    // nil means the metadata doesn't enumerate supported format versions (pre-v16) — don't validate against it
    var supportedFormatVersions: [UInt8]? { get }
    var supportedExtensionVersions: [UInt8] { get }

    func signedExtensions(forExtensionVersion version: UInt8) throws -> [SignedExtensionV14]
}

// V14/V15 have no per-version extension mapping: a single extension version 0 maps to the flat list,
// and they don't enumerate supported format versions.
public extension PostV14ExtrinsicMetadataProtocol {
    var supportedFormatVersions: [UInt8]? { nil }

    var supportedExtensionVersions: [UInt8] { [0] }

    func signedExtensions(forExtensionVersion version: UInt8) throws -> [SignedExtensionV14] {
        guard version == 0 else {
            throw PostV14ExtrinsicMetadataError.unsupportedExtensionVersion(version)
        }

        return signedExtensions
    }
}
