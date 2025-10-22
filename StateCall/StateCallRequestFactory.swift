import Foundation
import SubstrateSdk
import Operation_iOS

public typealias StateCallRequestParamsClosure = (DynamicScaleEncoding, RuntimeJsonContext) throws -> Void
public typealias StateCallRawParamClosure = () throws -> Data

public protocol StateCallResultDecoding {
    associatedtype Result

    func decode(data: Data, using codingFactory: RuntimeCoderFactoryProtocol) throws -> Result
}

public protocol StateCallStaticResultDecoding {
    associatedtype Result

    func decode(data: Data) throws -> Result
}

public struct StateCallResultFromTypeNameDecoder<T: Decodable>: StateCallResultDecoding {
    public typealias Result = T

    let typeName: String

    public func decode(data: Data, using codingFactory: RuntimeCoderFactoryProtocol) throws -> T {
        let decoder = try codingFactory.createDecoder(from: data)

        return try decoder.read(type: typeName).map(
            to: T.self,
            with: codingFactory.createRuntimeJsonContext().toRawContext()
        )
    }
}

public struct StateCallResultFromScaleTypeDecoder<T: ScaleCodable>: StateCallResultDecoding, StateCallStaticResultDecoding {
    public typealias Result = T

    public func decode(data: Data, using codingFactory: RuntimeCoderFactoryProtocol) throws -> T {
        let decoder = try codingFactory.createDecoder(from: data)

        return try decoder.read()
    }

    public func decode(data: Data) throws -> T {
        let decoder = try ScaleDecoder(data: data)
        return try T(scaleDecoder: decoder)
    }
}

public struct StateCallRawDataDecoder: StateCallResultDecoding, StateCallStaticResultDecoding {
    public typealias Result = Data

    public func decode(data: Data, using _: RuntimeCoderFactoryProtocol) throws -> Data {
        data
    }

    public func decode(data: Data) throws -> Data {
        data
    }
}

public protocol StateCallRequestFactoryProtocol {
    func createWrapper<V, Decoder: StateCallResultDecoding>(
        for functionName: String,
        paramsClosure: StateCallRequestParamsClosure?,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol,
        connection: JSONRPCEngine,
        resultDecoder: Decoder,
        at blockHash: BlockHash?
    ) -> CompoundOperationWrapper<V> where Decoder.Result == V

    func createStaticCodingWrapper<V, D: StateCallStaticResultDecoding>(
        for functionName: String,
        paramsClosure: StateCallRawParamClosure?,
        connection: JSONRPCEngine,
        decoder: D,
        at blockHash: BlockHash?
    ) -> CompoundOperationWrapper<V> where D.Result == V
}

public extension StateCallRequestFactoryProtocol {
    func createWrapper<V: Decodable>(
        for functionName: String,
        paramsClosure: StateCallRequestParamsClosure?,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol,
        connection: JSONRPCEngine,
        queryType: String,
        at blockHash: BlockHash? = nil
    ) -> CompoundOperationWrapper<V> {
        createWrapper(
            for: functionName,
            paramsClosure: paramsClosure,
            codingFactoryClosure: codingFactoryClosure,
            connection: connection,
            resultDecoder: StateCallResultFromTypeNameDecoder(typeName: queryType),
            at: blockHash
        )
    }

    func createWrapper<V: ScaleCodable>(
        for functionName: String,
        paramsClosure: StateCallRequestParamsClosure?,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol,
        connection: JSONRPCEngine,
        at blockHash: BlockHash? = nil
    ) -> CompoundOperationWrapper<V> {
        createWrapper(
            for: functionName,
            paramsClosure: paramsClosure,
            codingFactoryClosure: codingFactoryClosure,
            connection: connection,
            resultDecoder: StateCallResultFromScaleTypeDecoder<V>(),
            at: blockHash
        )
    }

    func createRawDataWrapper(
        for functionName: String,
        paramsClosure: StateCallRequestParamsClosure?,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol,
        connection: JSONRPCEngine,
        at blockHash: BlockHash? = nil
    ) -> CompoundOperationWrapper<Data> {
        createWrapper(
            for: functionName,
            paramsClosure: paramsClosure,
            codingFactoryClosure: codingFactoryClosure,
            connection: connection,
            resultDecoder: StateCallRawDataDecoder(),
            at: blockHash
        )
    }
}

public final class StateCallRequestFactory {
    let rpcTimeout: Int

    public init(rpcTimeout: Int = 60) {
        self.rpcTimeout = rpcTimeout
    }
}

extension StateCallRequestFactory: StateCallRequestFactoryProtocol {
    public func createWrapper<V, Decoder: StateCallResultDecoding>(
        for functionName: String,
        paramsClosure: StateCallRequestParamsClosure?,
        codingFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol,
        connection: JSONRPCEngine,
        resultDecoder: Decoder,
        at blockHash: BlockHash?
    ) -> CompoundOperationWrapper<V> where Decoder.Result == V {
        let requestOperation = ClosureOperation<StateCallRpc.Request> {
            let codingFactory = try codingFactoryClosure()
            let context = codingFactory.createRuntimeJsonContext()

            let encoder = codingFactory.createEncoder()

            // state call always require parameters even if the list is empty
            try paramsClosure?(encoder, context)

            let param = try encoder.encode()

            return StateCallRpc.Request(
                builtInFunction: functionName,
                blockHash: blockHash
            ) { container in
                try container.encode(param.toHex(includePrefix: true))
            }
        }

        let infoOperation = JSONRPCOperation<StateCallRpc.Request, String>(
            engine: connection,
            method: StateCallRpc.method,
            timeout: rpcTimeout
        )

        infoOperation.configurationBlock = {
            do {
                infoOperation.parameters = try requestOperation.extractNoCancellableResultData()
            } catch {
                infoOperation.result = .failure(error)
            }
        }

        infoOperation.addDependency(requestOperation)

        let mapOperation = ClosureOperation<V> {
            let coderFactory = try codingFactoryClosure()
            let result = try infoOperation.extractNoCancellableResultData()
            let resultData = try Data(hexString: result)

            return try resultDecoder.decode(data: resultData, using: coderFactory)
        }

        mapOperation.addDependency(infoOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [requestOperation, infoOperation])
    }

    public func createStaticCodingWrapper<V, D: StateCallStaticResultDecoding>(
        for functionName: String,
        paramsClosure: StateCallRawParamClosure?,
        connection: JSONRPCEngine,
        decoder: D,
        at blockHash: BlockHash?
    ) -> CompoundOperationWrapper<V> where D.Result == V {
        let requestOperation = ClosureOperation<StateCallRpc.Request> {
            let param = try paramsClosure?() ?? Data()

            return StateCallRpc.Request(
                builtInFunction: functionName,
                blockHash: blockHash
            ) { container in
                try container.encode(param.toHex(includePrefix: true))
            }
        }

        let infoOperation = JSONRPCOperation<StateCallRpc.Request, String>(
            engine: connection,
            method: StateCallRpc.method,
            timeout: rpcTimeout
        )

        infoOperation.configurationBlock = {
            do {
                infoOperation.parameters = try requestOperation.extractNoCancellableResultData()
            } catch {
                infoOperation.result = .failure(error)
            }
        }

        infoOperation.addDependency(requestOperation)

        let mapOperation = ClosureOperation<V> {
            let result = try infoOperation.extractNoCancellableResultData()
            let resultData = try Data(hexString: result)

            return try decoder.decode(data: resultData)
        }

        mapOperation.addDependency(infoOperation)

        return CompoundOperationWrapper(targetOperation: mapOperation, dependencies: [requestOperation, infoOperation])
    }
}
