import Foundation

public extension TypeRegistry {
    static func createFromRuntimeMetadata(
        _ runtimeMetadata: RuntimeMetadata,
        additionalTypes: Set<String> = []
    ) throws -> TypeRegistry {
        var allTypes: Set<String> = additionalTypes

        for module in runtimeMetadata.modules {
            if let storage = module.storage {
                for storageEntry in storage.entries {
                    switch storageEntry.type {
                    case let .plain(value):
                        allTypes.insert(value)
                    case let .map(map):
                        allTypes.insert(map.key)
                        allTypes.insert(map.value)
                    case let .doubleMap(map):
                        allTypes.insert(map.key1)
                        allTypes.insert(map.key2)
                        allTypes.insert(map.value)
                    case let .nMap(nMap):
                        nMap.keyVec.forEach { allTypes.insert($0) }
                        allTypes.insert(nMap.value)
                    }
                }
            }

            if let calls = module.calls {
                let callTypes = calls.flatMap { $0.arguments.map(\.type) }
                allTypes.formUnion(callTypes)
            }

            if let events = module.events {
                let eventTypes = events.flatMap(\.arguments)
                allTypes.formUnion(eventTypes)
            }

            let constantTypes = module.constants.map(\.type)
            allTypes.formUnion(constantTypes)
        }

        let jsonDic: [String: JSON] = allTypes.reduce(into: [String: JSON]()) { result, item in
            result[item] = .stringValue(item)
        }

        let json = JSON.dictionaryValue(["types": .dictionaryValue(jsonDic)])

        return try TypeRegistry.createFromTypesDefinition(
            json: json,
            additionalNodes: []
        )
    }
}
