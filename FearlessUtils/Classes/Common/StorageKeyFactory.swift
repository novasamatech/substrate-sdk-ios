import Foundation

public protocol StorageKeyFactoryProtocol: class {
    func createStorageKey(moduleName: String, serviceName: String) throws -> Data
    func createStorageKey(moduleName: String,
                          serviceName: String,
                          identifier: Data,
                          hasher: StorageKeyHasher) throws -> Data
}

public enum StorageKeyFactoryError: Error {
    case badSerialization
}

public protocol StorageKeyHasher: class {
    func hash(data: Data) throws -> Data
}

public final class Blake128Concat: StorageKeyHasher {
    public init() {}

    public func hash(data: Data) throws -> Data {
        try data.blake128Concat()
    }
}

public final class Twox64Concat: StorageKeyHasher {
    public init() {}

    public func hash(data: Data) throws -> Data {
        data.twox64Concat()
    }
}

public final class StorageKeyFactory: StorageKeyFactoryProtocol {
    public init() {}

    public func createStorageKey(moduleName: String, serviceName: String) throws -> Data {
        guard let moduleKey = moduleName.data(using: .utf8) else {
            throw StorageKeyFactoryError.badSerialization
        }

        guard let serviceKey = serviceName.data(using: .utf8) else {
            throw StorageKeyFactoryError.badSerialization
        }

        return moduleKey.xxh128() + serviceKey.xxh128()
    }

    public func createStorageKey(moduleName: String,
                                 serviceName: String,
                                 identifier: Data,
                                 hasher: StorageKeyHasher) throws -> Data {
        let subkey = try createStorageKey(moduleName: moduleName, serviceName: serviceName)

        let identifierHash: Data = try hasher.hash(data: identifier)

        return subkey + identifierHash
    }
}
