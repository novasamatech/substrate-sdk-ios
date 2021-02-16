import Foundation

public extension TypeRegistry {
    static func createFromRuntimeMetadata(_ runtimeMetadata: RuntimeMetadata,
                                          additionalTypes: Set<String> = []) throws -> TypeRegistry {
        var allTypes: Set<String> = additionalTypes

        for module in runtimeMetadata.modules {
            if let storage = module.storage {
                for storageEntry in storage.entries {
                    switch storageEntry.type {
                    case .plain(let value):
                        allTypes.insert(value)
                    case .map(let map):
                        allTypes.insert(map.key)
                        allTypes.insert(map.value)
                    case .doubleMap(let map):
                        allTypes.insert(map.key1)
                        allTypes.insert(map.key2)
                        allTypes.insert(map.value)
                    }
                }
            }

            if let calls = module.calls {
                let callTypes = calls.flatMap { $0.arguments.map { $0.type }}
                allTypes.formUnion(callTypes)
            }

            if let events = module.events {
                let eventTypes = events.flatMap { $0.arguments }
                allTypes.formUnion(eventTypes)
            }

            let constantTypes = module.constants.map { $0.type }
            allTypes.formUnion(constantTypes)
        }

        let jsonDic: [String: JSON] = allTypes.reduce(into: [String: JSON]()) { (result, item) in
            result[item] = .stringValue(item)
        }

        let json = JSON.dictionaryValue(["types": .dictionaryValue(jsonDic)])

        return try TypeRegistry.createFromTypesDefinition(json: json,
                                                          additionalNodes: [])
    }
}
