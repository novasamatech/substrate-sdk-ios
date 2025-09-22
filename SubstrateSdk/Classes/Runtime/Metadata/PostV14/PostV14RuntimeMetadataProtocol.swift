import Foundation

public protocol PostV14RuntimeMetadataProtocol: RuntimeMetadataProtocol {
    var types: RuntimeTypesLookup { get }
    var postV14Pallets: [PostV14PalletMetadataProtocol] { get }
    var postV14Extrinsic: PostV14ExtrinsicMetadataProtocol { get }
}

public extension PostV14RuntimeMetadataProtocol {
    func getCall(from module: String, with name: String) -> CallMetadata? {
        guard let pallet = postV14Pallets.first(where: { $0.name == module }) else {
            return nil
        }

        guard let callsTypeId = pallet.calls?.type, let callType = types.types
            .first(where: { $0.identifier == callsTypeId }) else {
            return nil
        }

        guard
            case let .variant(calls) = callType.type.typeDefinition,
            let call = calls.variants.first(where: { $0.name == name }) else {
            return nil
        }

        return convert(call: call)
    }

    func getCallByModuleIndex(_ moduleIndex: UInt8, callIndex: UInt8) -> CallMetadata? {
        guard let pallet = postV14Pallets.first(where: { $0.index == moduleIndex }) else {
            return nil
        }

        guard let callsTypeId = pallet.calls?.type, let callType = types.types
            .first(where: { $0.identifier == callsTypeId }) else {
            return nil
        }

        guard
            case let .variant(calls) = callType.type.typeDefinition,
            let call = calls.variants.first(where: { $0.index == callIndex }) else {
            return nil
        }

        return convert(call: call)
    }

    func getModuleIndex(_ name: String) -> UInt8? {
        postV14Pallets.first(where: { $0.name == name })?.index
    }

    func getModuleName(by index: UInt8) -> String? {
        postV14Pallets.first(where: { $0.index == index })?.name
    }

    func getCallIndex(in moduleName: String, callName: String) -> UInt8? {
        guard let pallet = postV14Pallets.first(where: { $0.name == moduleName }) else {
            return nil
        }

        guard let callsTypeId = pallet.calls?.type, let callType = types.types
            .first(where: { $0.identifier == callsTypeId }) else {
            return nil
        }

        guard
            case let .variant(calls) = callType.type.typeDefinition,
            let call = calls.variants.first(where: { $0.name == callName }) else {
            return nil
        }

        return call.index
    }

    func getStorageMetadata(in moduleName: String, storageName: String) -> StorageEntryMetadata? {
        guard
            let pallet = postV14Pallets.first(where: { $0.name == moduleName }),
            let storage = pallet.storage,
            let storageEntryMetadata = storage.entries.first(where: { $0.name == storageName }) else {
            return nil
        }

        let name = storageEntryMetadata.name
        let modifier = storageEntryMetadata.modifier
        let defaultValue = storageEntryMetadata.defaultValue
        let documentation = storageEntryMetadata.documentation

        guard let storageEntryType = convert(entry: storageEntryMetadata.type) else {
            return nil
        }

        return StorageEntryMetadata(
            name: name,
            modifier: modifier,
            type: storageEntryType,
            defaultValue: defaultValue,
            documentation: documentation
        )
    }

    func getConstant(in moduleName: String, constantName: String) -> ModuleConstantMetadata? {
        guard
            let pallet = postV14Pallets.first(where: { $0.name == moduleName }),
            let constant = pallet.constants.first(where: { $0.name == constantName }) else {
            return nil
        }

        return ModuleConstantMetadata(
            name: constant.name,
            type: String(constant.type),
            value: constant.value,
            documentation: constant.documentation
        )
    }

    func getEventForModuleIndex(_ moduleIndex: UInt8, eventIndex: UInt32) -> EventMetadata? {
        guard
            let pallet = postV14Pallets.first(where: { $0.index == moduleIndex }),
            let eventsType = pallet.events?.type,
            let events = types.types.first(where: { $0.identifier == eventsType }),
            case let .variant(variant) = events.type.typeDefinition,
            let event = variant.variants.first(where: { $0.index == eventIndex }) else {
            return nil
        }

        let arguments = event.fields.map { String($0.type) }

        return EventMetadata(name: event.name, arguments: arguments, documentation: event.docs)
    }

    func getSignedExtensions() -> [String] {
        postV14Extrinsic.signedExtensions.map(\.identifier)
    }

    func getSignedExtensionType(for identifier: String) -> String? {
        guard let signedExtension = postV14Extrinsic.signedExtensions.first(
            where: { $0.identifier == identifier }
        ) else {
            return nil
        }

        return String(signedExtension.type)
    }

    private func convert(call: RuntimeTypeVariantItem) -> CallMetadata {
        let name = call.name
        let docs = call.docs

        let arguments = call.fields.map {
            CallArgumentMetadata(name: $0.name ?? "", type: String($0.type))
        }

        return CallMetadata(name: name, arguments: arguments, documentation: docs)
    }

    private func convert(entry: StorageEntryTypeV14) -> StorageEntryType? {
        switch entry {
        case let .plain(entryType):
            return StorageEntryType.plain(String(entryType))
        case let .map(entryType):
            if entryType.hashers.count == 1 {
                let mapEntry = MapEntry(
                    hasher: entryType.hashers[0],
                    key: String(entryType.key),
                    value: String(entryType.value),
                    unused: false
                )

                return StorageEntryType.map(mapEntry)
            } else if entryType.hashers.count == 2 {
                guard
                    let keys = extractKeysFromTupleId(entryType.key),
                    keys.count == entryType.hashers.count else {
                    return nil
                }

                let doubleMapEntry = DoubleMapEntry(
                    hasher: entryType.hashers[0],
                    key1: String(keys[0]),
                    key2: String(keys[1]),
                    value: String(entryType.value),
                    key2Hasher: entryType.hashers[1]
                )

                return StorageEntryType.doubleMap(doubleMapEntry)
            } else {
                guard
                    let keys = extractKeysFromTupleId(entryType.key),
                    keys.count == entryType.hashers.count else {
                    return nil
                }

                let keyVec = keys.map { String($0) }
                let nMapEntry = NMapEntry(
                    keyVec: keyVec,
                    hashers: entryType.hashers,
                    value: String(entryType.value)
                )

                return StorageEntryType.nMap(nMapEntry)
            }
        }
    }

    private func extractKeysFromTupleId(_ tupleId: SiLookupId) -> [SiLookupId]? {
        guard
            let keysType = types.types.first(where: { $0.identifier == tupleId }),
            case let .tuple(value) = keysType.type.typeDefinition else {
            return nil
        }

        return value.components
    }
}
