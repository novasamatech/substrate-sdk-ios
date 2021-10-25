import Foundation

public protocol RuntimeMetadataProtocol {
    func getCall(from module: String, with name: String) -> CallMetadata?

    func getCallByModuleIndex(_ moduleIndex: UInt8, callIndex: UInt8) -> CallMetadata?

    func getModuleIndex(_ name: String) -> UInt8?

    func getModuleName(by index: UInt8) -> String?

    func getCallIndex(in moduleName: String, callName: String) -> UInt8?

    func getStorageMetadata(in moduleName: String, storageName: String) -> StorageEntryMetadata?

    func getConstant(in moduleName: String, constantName: String) -> ModuleConstantMetadata?

    func getEventForModuleIndex(_ moduleIndex: UInt8, eventIndex: UInt32) -> EventMetadata?

    func getSignedExtensions() -> [String]
}

public struct RuntimeMetadata: RuntimeMetadataProtocol {
    public let modules: [ModuleMetadata]
    public let extrinsic: ExtrinsicMetadata

    public init(modules: [ModuleMetadata], extrinsic: ExtrinsicMetadata) {
        self.modules = modules
        self.extrinsic = extrinsic
    }

    public func getCall(from module: String, with name: String) -> CallMetadata? {
        modules
            .first(where: { $0.name == module })?
            .calls?.first(where: { $0.name == name })
    }

    public func getCallByModuleIndex(_ moduleIndex: UInt8, callIndex: UInt8) -> CallMetadata? {
        guard let module = modules.first(where: { $0.index == moduleIndex }) else {
            return nil
        }

        guard let calls = module.calls, callIndex < calls.count else {
            return nil
        }

        return calls[Int(callIndex)]
    }

    public func getModuleIndex(_ name: String) -> UInt8? {
        modules.first(where: { $0.name == name })?.index
    }

    public func getModuleName(by index: UInt8) -> String? {
        modules.first(where: { $0.index == index })?.name
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

    public func getEventForModuleIndex(_ moduleIndex: UInt8, eventIndex: UInt32) -> EventMetadata? {
        guard let module = modules.first(where: { $0.index == moduleIndex }) else {
            return nil
        }

        guard let events = module.events, eventIndex < events.count else {
            return nil
        }

        return events[Int(eventIndex)]
    }

    public func getSignedExtensions() -> [String] {
        extrinsic.signedExtensions
    }
}

extension RuntimeMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try modules.encode(scaleEncoder: scaleEncoder)
        try extrinsic.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.modules = try [ModuleMetadata](scaleDecoder: scaleDecoder)
        self.extrinsic = try ExtrinsicMetadata(scaleDecoder: scaleDecoder)
    }
}
