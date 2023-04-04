import Foundation

class JSONRPCRequestFactory {
    enum IdType {
        case existing(UInt16)
        case generate(skipping: Set<UInt16>)
    }

    lazy var jsonEncoder = JSONEncoder()
    lazy var jsonDecoder = JSONDecoder()

    let version: String

    init(version: String) {
        self.version = version
    }

    func prepareRequestData<P: Encodable>(
        method: String,
        requestId: UInt16,
        params: P?
    ) throws -> Data {
        if let params = params {
            let info = JSONRPCInfo(
                identifier: requestId,
                jsonrpc: version,
                method: method,
                params: params
            )

            return try jsonEncoder.encode(info)
        } else {
            let info = JSONRPCInfo(
                identifier: requestId,
                jsonrpc: version,
                method: method,
                params: [String]()
            )

            return try jsonEncoder.encode(info)
        }
    }

    func prepareBatchRequestItem<P: Encodable>(
        method: String,
        params: P?,
        idType: IdType
    ) throws -> JSONRPCBatchRequestItem {
        let requestId = getRequestId(for: idType)

        let data = try prepareRequestData(method: method, requestId: requestId, params: params)

        return JSONRPCBatchRequestItem(requestId: requestId, data: data)
    }

    func prepareBatchRequest(
        batchId: JSONRPCBatchId,
        from batchItems: [JSONRPCBatchRequestItem],
        options: JSONRPCOptions,
        completion closure: (([Result<JSON, Error>]) -> Void)?
    ) throws -> JSONRPCRequest {
        let jsonList = try batchItems.map { try jsonDecoder.decode(JSON.self, from: $0.data) }
        let itemIds = batchItems.map { $0.requestId }

        let data = try jsonEncoder.encode(JSON.arrayValue(jsonList))

        let handler: JSONRPCBatchHandler?

        if let closure = closure {
            handler = JSONRPCBatchHandler(itemIds: itemIds, completionClosure: closure)
        } else {
            handler = nil
        }

        return JSONRPCRequest(
            requestId: .batch(batchId: batchId, itemIds: itemIds),
            data: data,
            options: options,
            responseHandler: handler
        )
    }

    func prepareRequest<P: Encodable, T: Decodable>(
        method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?,
        idType: IdType
    ) throws -> JSONRPCRequest {
        let requestId = getRequestId(for: idType)
        let data: Data = try prepareRequestData(method: method, requestId: requestId, params: params)

        let handler: JSONRPCResponseHandling?

        if let completionClosure = closure {
            handler = JSONRPCResponseHandler(completionClosure: completionClosure)
        } else {
            handler = nil
        }

        let request = JSONRPCRequest(
            requestId: .single(requestId),
            data: data,
            options: options,
            responseHandler: handler
        )

        return request
    }

    func getRequestId(for type: IdType) -> UInt16 {
        switch type {
        case let .existing(identifier):
            return identifier
        case let .generate(skippingSet):
            return generateRequestId(skipping: skippingSet)
        }
    }

    func generateRequestId(skipping existingIds: Set<UInt16>) -> UInt16 {
        var targetId = (1 ... UInt16.max).randomElement() ?? 1

        while existingIds.contains(targetId) {
            targetId += 1
        }

        return targetId
    }
}
