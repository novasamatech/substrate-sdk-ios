import Foundation

public protocol StorageKeyFactoryProtocol: class {
    func createStorageKey(moduleName: String, storageName: String) throws -> Data

    func createStorageKey(moduleName: String,
                          storageName: String,
                          key: Data,
                          hasher: StorageHasher) throws -> Data

    func createStorageKey(moduleName: String,
                          storageName: String,
                          key1: Data,
                          hasher1: StorageHasher,
                          key2: Data,
                          hasher2: StorageHasher) throws -> Data
}

public enum StorageKeyFactoryError: Error {
    case badSerialization
}

public final class StorageKeyFactory: StorageKeyFactoryProtocol {
    public init() {}

    public func createStorageKey(moduleName: String, storageName: String) throws -> Data {
        guard let moduleKey = moduleName.data(using: .utf8) else {
            throw StorageKeyFactoryError.badSerialization
        }

        guard let serviceKey = storageName.data(using: .utf8) else {
            throw StorageKeyFactoryError.badSerialization
        }

        return moduleKey.twox128() + serviceKey.twox128()
    }

    public func createStorageKey(moduleName: String,
                                 storageName: String,
                                 key: Data,
                                 hasher: StorageHasher) throws -> Data {
        let subkey = try createStorageKey(moduleName: moduleName, storageName: storageName)

        let keyHash: Data = try hasher.hash(data: key)

        return subkey + keyHash
    }

    public func createStorageKey(moduleName: String,
                                 storageName: String,
                                 key1: Data,
                                 hasher1: StorageHasher,
                                 key2: Data,
                                 hasher2: StorageHasher) throws -> Data {
        let subkey = try createStorageKey(moduleName: moduleName,
                                          storageName: storageName,
                                          key: key1,
                                          hasher: hasher1)

        let key2Hash: Data = try hasher2.hash(data: key2)

        return subkey + key2Hash
    }
}
