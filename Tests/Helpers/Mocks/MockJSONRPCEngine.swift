import Foundation
import SubstrateSdk

public final class MockJSONRPCEngine: JSONRPCEngine {
    public struct RecordedCall {
        public let method: String
        public let params: JSON?
        public let options: JSONRPCOptions
    }

    public typealias Responder = (RecordedCall, Int) -> Result<JSON, Error>

    public var responder: Responder
    public let responseQueue: DispatchQueue

    private let mutex = NSLock()
    private var nextRequestId: UInt16 = 1
    private var recordedCalls: [RecordedCall] = []
    private var recordedCancelledIds: [UInt16] = []

    public init(
        responseQueue: DispatchQueue = .global(),
        responder: @escaping Responder = { _, _ in .success(.null) }
    ) {
        self.responseQueue = responseQueue
        self.responder = responder
    }

    public var calls: [RecordedCall] {
        mutex.lock()
        defer { mutex.unlock() }
        return recordedCalls
    }

    public var cancelledIds: [UInt16] {
        mutex.lock()
        defer { mutex.unlock() }
        return recordedCancelledIds
    }

    public func callMethod<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16 {
        let paramsJSON: JSON? = try params.map {
            try JSONDecoder().decode(JSON.self, from: JSONEncoder().encode($0))
        }

        mutex.lock()

        let call = RecordedCall(method: method, params: paramsJSON, options: options)
        let index = recordedCalls.count
        recordedCalls.append(call)

        let requestId = nextRequestId
        nextRequestId += 1

        let responder = self.responder

        mutex.unlock()

        // JSONRPCOperation registers the pending request only after callMethod returns and
        // holds a non-recursive lock while calling us, so a synchronous reply would deadlock
        // or be dropped.
        responseQueue.async {
            let result: Result<T, Error> = responder(call, index).flatMap { json in
                Result { try JSONDecoder().decode(T.self, from: JSONEncoder().encode(json)) }
            }

            closure?(result)
        }

        return requestId
    }

    public func subscribe<P: Encodable, T: Decodable>(
        _: String,
        params _: P?,
        unsubscribeMethod _: String,
        options _: JSONRPCOptions,
        onSubscribed _: ((JSONRPCSubscriptionId) -> Void)?,
        updateClosure _: @escaping (T) -> Void,
        failureClosure _: @escaping (Error, Bool) -> Void
    ) throws -> UInt16 {
        throw JSONRPCEngineError.unsupportedMethod
    }

    public func cancelForIdentifiers(_ identifiers: [UInt16], sendUnsubscribe _: Bool) {
        mutex.lock()
        recordedCancelledIds.append(contentsOf: identifiers)
        mutex.unlock()
    }

    public func addBatchCallMethod<P: Encodable>(_: String, params _: P?, batchId _: JSONRPCBatchId) throws {
        throw JSONRPCEngineError.unsupportedMethod
    }

    public func submitBatch(
        for _: JSONRPCBatchId,
        options _: JSONRPCOptions,
        completion _: (([Result<JSON, Error>]) -> Void)?
    ) throws -> [UInt16] {
        throw JSONRPCEngineError.unsupportedMethod
    }

    public func clearBatch(for _: JSONRPCBatchId) {}
}
