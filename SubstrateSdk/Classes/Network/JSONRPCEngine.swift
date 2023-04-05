import Foundation

public enum JSONRPCEngineError: Error {
    case emptyResult
    case remoteCancelled
    case clientCancelled
    case unknownError
    case unsupportedMethod
}

public protocol JSONRPCResponseHandling {
    func handle(data: Data, for identifier: UInt16)
    func handle(error: Error, for identifier: UInt16)
}

public typealias JSONRPCBatchId = String

public struct JSONRPCBatchRequestItem {
    public let requestId: UInt16
    public let data: Data
}

public enum JSONRPCRequestId: Hashable, Equatable {
    case single(UInt16)
    case batch(batchId: JSONRPCBatchId, itemIds: [UInt16])

    var itemIds: [UInt16] {
        switch self {
        case let .single(identifier):
            return [identifier]
        case let .batch(_, itemIds):
            return itemIds
        }
    }
}

public struct JSONRPCRequest: Equatable {
    public let requestId: JSONRPCRequestId
    public let data: Data
    public let options: JSONRPCOptions
    public let responseHandler: JSONRPCResponseHandling?

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.requestId == rhs.requestId }
}

struct JSONRPCResponseHandler<T: Decodable>: JSONRPCResponseHandling {
    public let completionClosure: (Result<T, Error>) -> Void

    func handle(data: Data, for identifier: UInt16) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(JSONRPCData<T>.self, from: data)

            completionClosure(.success(response.result))

        } catch {
            completionClosure(.failure(error))
        }
    }

    func handle(error: Error, for identifier: UInt16) {
        completionClosure(.failure(error))
    }
}

// Class to share between multiple batch items to gather a single response
class JSONRPCBatchHandler: JSONRPCResponseHandling {
    let itemIds: [UInt16]

    private var receivedResponses: [UInt16: Result<JSON, Error>] = [:]

    init(itemIds: [UInt16], completionClosure: @escaping ([Result<JSON, Error>]) -> Void) {
        self.itemIds = itemIds
        self.completionClosure = completionClosure
    }

    public let completionClosure: ([Result<JSON, Error>]) -> Void

    private func createResult(from rpcData: JSONRPCData<JSON?>) -> Result<JSON, Error> {
        if let value = rpcData.result {
            return .success(value)
        } else if let error = rpcData.error {
            return .failure(error)
        } else {
            return .failure(JSONRPCEngineError.emptyResult)
        }
    }

    private func notifyCallbackIfReady() {
        if receivedResponses.count == itemIds.count {
            let results = itemIds.compactMap { receivedResponses[$0] }
            completionClosure(results)
        }
    }

    func handle(data: Data, for identifier: UInt16) {
        guard itemIds.contains(identifier) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(JSONRPCData<JSON?>.self, from: data)

            receivedResponses[identifier] = createResult(from: response)
        } catch {
            receivedResponses[identifier] = .failure(error)
        }

        notifyCallbackIfReady()
    }

    func handle(error: Error, for identifier: UInt16) {
        receivedResponses[identifier] = .failure(error)

        notifyCallbackIfReady()
    }
}

public struct JSONRPCOptions {
    public let resendOnReconnect: Bool

    public init(resendOnReconnect: Bool = true) {
        self.resendOnReconnect = resendOnReconnect
    }
}

public protocol JSONRPCSubscribing: AnyObject {
    var requestId: UInt16 { get }
    var requestData: Data { get }
    var requestOptions: JSONRPCOptions { get }
    var remoteId: String? { get set }
    var unsubscribeMethod: String { get }

    func handle(data: Data) throws
    func handle(error: Error, unsubscribed: Bool)
}

public final class JSONRPCSubscription<T: Decodable>: JSONRPCSubscribing {
    public let requestId: UInt16
    public let requestData: Data
    public let requestOptions: JSONRPCOptions
    public var remoteId: String?
    public let unsubscribeMethod: String

    private lazy var jsonDecoder = JSONDecoder()

    public let updateClosure: (T) -> Void
    public let failureClosure: (Error, Bool) -> Void

    public init(
        requestId: UInt16,
        requestData: Data,
        requestOptions: JSONRPCOptions,
        unsubscribeMethod: String,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    ) {
        self.requestId = requestId
        self.requestData = requestData
        self.requestOptions = requestOptions
        self.unsubscribeMethod = unsubscribeMethod
        self.updateClosure = updateClosure
        self.failureClosure = failureClosure
    }

    public func handle(data: Data) throws {
        let entity = try jsonDecoder.decode(T.self, from: data)
        updateClosure(entity)
    }

    public func handle(error: Error, unsubscribed: Bool) {
        failureClosure(error, unsubscribed)
    }
}

public protocol JSONRPCEngine: AnyObject {
    func callMethod<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16

    func subscribe<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        unsubscribeMethod: String,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    )
        throws -> UInt16

    func cancelForIdentifiers(_ identifiers: [UInt16])

    func addBatchCallMethod<P: Encodable>(
        _ method: String,
        params: P?,
        batchId: JSONRPCBatchId
    ) throws

    func submitBatch(
        for batchId: JSONRPCBatchId,
        options: JSONRPCOptions,
        completion closure: (([Result<JSON, Error>]) -> Void)?
    ) throws -> [UInt16]

    func clearBatch(for batchId: JSONRPCBatchId)
}

public extension JSONRPCEngine {
    func submitBatch(
        for batchId: JSONRPCBatchId,
        completion closure: (([Result<JSON, Error>]) -> Void)?
    ) throws -> [UInt16] {
        try submitBatch(for: batchId, options: JSONRPCOptions(), completion: closure)
    }

    func callMethod<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16 {
        try callMethod(
            method,
            params: params,
            options: JSONRPCOptions(),
            completion: closure
        )
    }

    func subscribe<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    ) throws -> UInt16 {
        try subscribe(
            method,
            params: params,
            unsubscribeMethod: RPCMethod.storageUnsubscribe,
            updateClosure: updateClosure,
            failureClosure: failureClosure
        )
    }

    func cancelForIdentifier(_ identifier: UInt16) {
        cancelForIdentifiers([identifier])
    }
}
