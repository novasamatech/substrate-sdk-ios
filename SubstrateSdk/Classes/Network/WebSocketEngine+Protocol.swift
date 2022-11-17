import Foundation

extension WebSocketEngine: JSONRPCEngine {
    public func addBatchCallMethod<P: Encodable>(
        _ method: String,
        params: P?,
        batchId: JSONRPCBatchId
    ) throws {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let batchItem = try prepareBatchRequestItem(method: method, params: params)
        storeBatchItem(batchItem, for: batchId)
    }

    public func submitBatch(
        for batchId: JSONRPCBatchId,
        options: JSONRPCOptions,
        completion closure: (([Result<JSON, Error>]) -> Void)?
    ) throws -> UInt16 {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        guard let batchItems = partialBatches[batchId], let requestId = batchItems.first?.requestId else {
            throw JSONRPCEngineError.emptyResult
        }

        clearPartialBatchStorage(for: batchId)

        let request = try prepareBatchRequest(
            requestId: requestId,
            from: batchItems,
            options: options,
            completion: closure
        )

        updateConnectionForRequest(request)

        return requestId
    }

    public func clearBatch(for batchId: JSONRPCBatchId) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        clearPartialBatchStorage(for: batchId)
    }

    public func callMethod<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16 {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let request = try prepareRequest(
            method: method,
            params: params,
            options: options,
            completion: closure
        )

        updateConnectionForRequest(request)

        return request.requestId
    }

    public func subscribe<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        unsubscribeMethod: String,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    ) throws -> UInt16 {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let completion: ((Result<String, Error>) -> Void)? = nil

        let request = try prepareRequest(
            method: method,
            params: params,
            options: JSONRPCOptions(resendOnReconnect: true),
            completion: completion
        )

        let subscription = JSONRPCSubscription(
            requestId: request.requestId,
            requestData: request.data,
            requestOptions: request.options,
            unsubscribeMethod: unsubscribeMethod,
            updateClosure: updateClosure,
            failureClosure: failureClosure
        )

        addSubscription(subscription)

        updateConnectionForRequest(request)

        return request.requestId
    }

    public func cancelForIdentifier(_ identifier: UInt16) {
        mutex.lock()

        cancelRequestForLocalId(identifier)

        mutex.unlock()
    }
}
