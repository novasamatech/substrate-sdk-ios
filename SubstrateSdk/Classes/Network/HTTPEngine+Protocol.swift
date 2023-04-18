import Foundation

extension HTTPEngine: JSONRPCEngine {
    public func subscribe<P, T>(
        _ method: String,
        params: P?,
        unsubscribeMethod: String,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    ) throws -> UInt16 where P: Encodable, T: Decodable {
        throw JSONRPCEngineError.unsupportedMethod
    }

    public func callMethod<P, T>(
        _ method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16 where P: Encodable, T: Decodable {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let requestId = generateRequestId()
        let request = try requestFactory.prepareRequest(
            method: method,
            params: params,
            options: options,
            completion: closure,
            idType: .existing(requestId)
        )

        send(
            request: request,
            url: selectedURL,
            timeout: timeout,
            encoder: requestFactory.jsonEncoder,
            decoder: requestFactory.jsonDecoder
        )

        return requestId
    }

    public func cancelForIdentifiers(_ identifiers: [UInt16]) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        for identifier in identifiers {
            unbindResendAttempts(for: identifier)

            if let operation = unbindOperation(for: identifier) {
                operation.cancel()
            }
        }
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

        send(
            request: request,
            url: selectedURL,
            timeout: timeout,
            encoder: requestFactory.jsonEncoder,
            decoder: requestFactory.jsonDecoder
        )

        return request.requestId.itemIds
    }

    public func addBatchCallMethod<P>(_ method: String, params: P?, batchId: JSONRPCBatchId) throws where P: Encodable {
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

    public func clearBatch(for batchId: JSONRPCBatchId) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        clearPartialBatchStorage(for: batchId)
    }
}
