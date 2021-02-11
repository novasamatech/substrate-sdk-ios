import Foundation

public struct RuntimeMetadata {
    public let metaReserved: UInt32
    public let runtimeMetadataVersion: UInt8
    public let modules: [ModuleMetadata]
    public let extrinsic: ExtrinsicMetadata

    public init(metaReserved: UInt32,
                runtimeMetadataVersion: UInt8,
                modules: [ModuleMetadata],
                extrinsic: ExtrinsicMetadata) {
        self.modules = modules
        self.extrinsic = extrinsic
        self.metaReserved = metaReserved
        self.runtimeMetadataVersion = runtimeMetadataVersion
    }
}

extension RuntimeMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try metaReserved.encode(scaleEncoder: scaleEncoder)
        try runtimeMetadataVersion.encode(scaleEncoder: scaleEncoder)
        try modules.encode(scaleEncoder: scaleEncoder)
        try extrinsic.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.metaReserved = try UInt32(scaleDecoder: scaleDecoder)
        self.runtimeMetadataVersion = try UInt8(scaleDecoder: scaleDecoder)
        self.modules = try [ModuleMetadata](scaleDecoder: scaleDecoder)
        self.extrinsic = try ExtrinsicMetadata(scaleDecoder: scaleDecoder)
    }
}
