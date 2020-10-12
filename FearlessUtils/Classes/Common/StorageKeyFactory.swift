import Foundation

public protocol StorageKeyFactoryProtocol {
    func createStorageKey(moduleName: String, serviceName: String) throws -> Data
    func createStorageKey(moduleName: String, serviceName: String, identifier: Data) throws -> Data
}

public enum StorageKeyFactoryError: Error {
    case badSerialization
}

public struct StorageKeyFactory: StorageKeyFactoryProtocol {
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

    public func createStorageKey(moduleName: String, serviceName: String, identifier: Data) throws -> Data {
        let subkey = try createStorageKey(moduleName: moduleName, serviceName: serviceName)

        let identifierHash = try identifier.blake128Concat()

        return subkey + identifierHash
    }
}
