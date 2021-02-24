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

    public func getFunction(from module: String, with name: String) -> FunctionMetadata? {
        modules
            .first(where: { $0.name == module })?
            .calls?.first(where: { $0.name == name })
    }

    public func getModuleIndex(_ name: String) -> UInt8? {
        modules.first(where: { $0.name == name })?.index
    }

    public func getCallIndex(in moduleName: String, callName: String) -> UInt8? {
        guard let index = modules.first(where: { $0.name == moduleName })?.calls?
                .firstIndex(where: { $0.name == callName}) else {
            return nil
        }

        return UInt8(index)
    }

    public func getStorageMetadata(in moduleName: String, storageName: String) -> StorageEntryMetadata? {
        modules.first(where: { $0.name == moduleName })?
            .storage?.entries.first(where: { $0.name == storageName})
    }

    public func getConstant(in moduleName: String, constantName: String) -> ModuleConstantMetadata? {
        modules.first(where: { $0.name == moduleName })?
            .constants.first(where: { $0.name == constantName})
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
