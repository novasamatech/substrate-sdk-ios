import Foundation
import Operation_iOS
import SubstrateSdk
import SubstrateStorageQuery

public protocol SubscriptionRequestProtocol {
    var localKey: String { get }

    var storagePath: StorageCodingPath { get }

    func createKeyEncodingWrapper(
        using storageKeyFactory: StorageKeyFactoryProtocol,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<Data>
}

public struct UnkeyedSubscriptionRequest: SubscriptionRequestProtocol {
    public let storagePath: StorageCodingPath
    public let localKey: String
    
    public init(storagePath: StorageCodingPath, localKey: String) {
        self.storagePath = storagePath
        self.localKey = localKey
    }

    public func createKeyEncodingWrapper(
        using storageKeyFactory: StorageKeyFactoryProtocol,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<Data> {
        let operation = UnkeyedEncodingOperation(path: storagePath, storageKeyFactory: storageKeyFactory)
        operation.configurationBlock = {
            do {
                operation.codingFactory = try codingFactoryClosure()
            } catch {
                operation.result = .failure(error)
            }
        }

        return CompoundOperationWrapper(targetOperation: operation)
    }
}

public struct MapSubscriptionRequest<T: Encodable>: SubscriptionRequestProtocol {
    public let storagePath: StorageCodingPath
    public let localKey: String
    public let keyParamClosure: () throws -> T
    public let paramEncoder: ((T) throws -> Data)?

    public init(
        storagePath: StorageCodingPath,
        localKey: String,
        keyParamClosure: @escaping () throws -> T,
        paramEncoder: ((T) throws -> Data)? = nil
    ) {
        self.storagePath = storagePath
        self.localKey = localKey
        self.keyParamClosure = keyParamClosure
        self.paramEncoder = paramEncoder
    }

    public func createKeyEncodingWrapper(
        using storageKeyFactory: StorageKeyFactoryProtocol,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<Data> {
        let encodingOperation = MapKeyEncodingOperation<T>(
            path: storagePath,
            storageKeyFactory: storageKeyFactory,
            paramEncoder: paramEncoder
        )

        encodingOperation.configurationBlock = {
            do {
                let keyParam = try keyParamClosure()
                encodingOperation.keyParams = [keyParam]

                encodingOperation.codingFactory = try codingFactoryClosure()
            } catch {
                encodingOperation.result = .failure(error)
            }
        }

        let mappingOperation = ClosureOperation<Data> {
            guard let remoteKey = try encodingOperation.extractNoCancellableResultData().first else {
                throw BaseOperationError.unexpectedDependentResult
            }

            return remoteKey
        }

        mappingOperation.addDependency(encodingOperation)

        return CompoundOperationWrapper(targetOperation: mappingOperation, dependencies: [encodingOperation])
    }
}

public struct DoubleMapSubscriptionRequest<T1: Encodable, T2: Encodable>: SubscriptionRequestProtocol {
    public let storagePath: StorageCodingPath
    public let localKey: String
    public let keyParamClosure: () throws -> (T1, T2)
    public let param1Encoder: ((T1) throws -> Data)?
    public let param2Encoder: ((T2) throws -> Data)?

    public init(
        storagePath: StorageCodingPath,
        localKey: String,
        keyParamClosure: @escaping () throws -> (T1, T2),
        param1Encoder: ((T1) throws -> Data)? = nil,
        param2Encoder: ((T2) throws -> Data)? = nil
    ) {
        self.storagePath = storagePath
        self.localKey = localKey
        self.keyParamClosure = keyParamClosure
        self.param1Encoder = param1Encoder
        self.param2Encoder = param2Encoder
    }

    public func createKeyEncodingWrapper(
        using storageKeyFactory: StorageKeyFactoryProtocol,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) -> CompoundOperationWrapper<Data> {
        let encodingOperation = DoubleMapKeyEncodingOperation<T1, T2>(
            path: storagePath,
            storageKeyFactory: storageKeyFactory,
            param1Encoder: param1Encoder,
            param2Encoder: param2Encoder
        )

        encodingOperation.configurationBlock = {
            do {
                let keyParams = try keyParamClosure()
                encodingOperation.keyParams1 = [keyParams.0]
                encodingOperation.keyParams2 = [keyParams.1]

                encodingOperation.codingFactory = try codingFactoryClosure()
            } catch {
                encodingOperation.result = .failure(error)
            }
        }

        let mappingOperation = ClosureOperation<Data> {
            guard let remoteKey = try encodingOperation.extractNoCancellableResultData().first else {
                throw BaseOperationError.unexpectedDependentResult
            }

            return remoteKey
        }

        mappingOperation.addDependency(encodingOperation)

        return CompoundOperationWrapper(targetOperation: mappingOperation, dependencies: [encodingOperation])
    }
}
