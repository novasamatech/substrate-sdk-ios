import Foundation

public struct ExtrinsicMetadata {
    public let version: UInt8
    public let signedExtensions: [String]

    public init(version: UInt8, signedExtensions: [String]) {
        self.version = version
        self.signedExtensions = signedExtensions
    }
}

extension ExtrinsicMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try version.encode(scaleEncoder: scaleEncoder)
        try signedExtensions.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        version = try UInt8(scaleDecoder: scaleDecoder)
        signedExtensions = try [String](scaleDecoder: scaleDecoder)
    }
}
