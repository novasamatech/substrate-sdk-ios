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

        let requestId = generateRequestId()
        let batchItem = try requestFactory.prepareBatchRequestItem(
            method: method,
            params: params,
            idType: .existing(requestId)
        )

        storeBatchItem(batchItem, for: batchId)
    }

    public func submitBatch(
        for batchId: JSONRPCBatchId,
        options: JSONRPCOptions,
        completion closure: (([Result<JSON, Error>]) -> Void)?
    ) throws -> [UInt16] {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        guard let batchItems = partialBatches[batchId] else {
            throw JSONRPCEngineError.emptyResult
        }

        clearPartialBatchStorage(for: batchId)

        let request = try requestFactory.prepareBatchRequest(
            batchId: batchId,
            from: batchItems,
            options: options,
            completion: closure
        )

        updateConnectionForRequest(request)

        return request.requestId.itemIds
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

        let requestId = generateRequestId()
        let request = try prepareRequest(
            method: method,
            params: params,
            options: options,
            completion: closure,
            preGeneratedRequestId: requestId
        )

        updateConnectionForRequest(request)

        return requestId
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

        let requestId = generateRequestId()
        let request = try prepareRequest(
            method: method,
            params: params,
            options: JSONRPCOptions(resendOnReconnect: true),
            completion: completion,
            preGeneratedRequestId: requestId
        )

        let subscription = JSONRPCSubscription(
            requestId: requestId,
            requestData: request.data,
            requestOptions: request.options,
            unsubscribeMethod: unsubscribeMethod,
            updateClosure: updateClosure,
            failureClosure: failureClosure
        )

        addSubscription(subscription)

        updateConnectionForRequest(request)

        return requestId
    }

    public func cancelForIdentifiers(_ identifiers: [UInt16]) {
        mutex.lock()

        identifiers.forEach { identifier in
            cancelRequestForLocalId(identifier)
        }

        mutex.unlock()
    }
}
