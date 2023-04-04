import Foundation
import RobinHood

public final class HTTPEngine {
    struct Response {
        let basicInfo: JSONRPCBasicData
        let originalData: Data
    }

    public let urls: [URL]

    public let name: String?
    public let logger: SDKLoggerProtocol?
    public let completionQueue: DispatchQueue
    public let operationQueue: OperationQueue
    public let timeout: TimeInterval
    public let customNodeSwitcher: JSONRPCNodeSwitching?

    internal let requestFactory: JSONRPCRequestFactory

    internal let mutex = NSLock()

    private(set) var inProgressRequests: [UInt16: JSONRPCRequestId] = [:]
    private(set) var requestIdMapping: [JSONRPCRequestId: Operation] = [:]
    private(set) var requestAttempts: [JSONRPCRequestId: Set<URL>] = [:]
    private(set) var partialBatches: [String: [JSONRPCBatchRequestItem]] = [:]

    public init(
        urls: [URL],
        operationQueue: OperationQueue,
        version: String = "2.0",
        customNodeSwitcher: JSONRPCNodeSwitching? = nil,
        timeout: TimeInterval = 60,
        completionQueue: DispatchQueue? = nil,
        name: String? = nil,
        logger: SDKLoggerProtocol? = nil
    ) {
        self.urls = urls
        self.requestFactory = JSONRPCRequestFactory(version: version)
        self.completionQueue = completionQueue ?? JSONRPCEngineShared.processingQueue
        self.customNodeSwitcher = customNodeSwitcher
        self.operationQueue = operationQueue
        self.timeout = timeout
        self.name = name
        self.logger = logger
    }

    func storeBatchItem(_ item: JSONRPCBatchRequestItem, for batchId: JSONRPCBatchId) {
        var items = partialBatches[batchId] ?? []
        items.append(item)

        partialBatches[batchId] = items
    }

    func clearPartialBatchStorage(for batchId: JSONRPCBatchId) {
        partialBatches[batchId] = nil
    }

    func bindRequest(request: JSONRPCRequest, operation: Operation) {
        requestIdMapping[request.requestId] = operation

        for identifier in request.requestId.itemIds {
            inProgressRequests[identifier] = request.requestId
        }
    }

    func unbindRequest(request: JSONRPCRequest, operation: Operation) -> Bool {
        guard requestIdMapping[request.requestId] === operation else {
            return false
        }

        requestIdMapping[request.requestId] = nil

        for identifier in request.requestId.itemIds {
            inProgressRequests[identifier] = nil
        }

        return true
    }

    func unbindOperation(for identifier: UInt16) -> Operation? {
        guard let requestId = inProgressRequests[identifier] else {
            return nil
        }

        let operation = requestIdMapping[requestId]

        inProgressRequests[identifier] = nil
        requestIdMapping[requestId] = nil

        return operation
    }

    func generateRequestId() -> UInt16 {
        let pendingItems = inProgressRequests.keys
        let partialBatches = partialBatches.values.flatMap { batch in
            batch.map { $0.requestId }
        }

        let existingIds: Set<UInt16> = Set(pendingItems + partialBatches)

        return requestFactory.generateRequestId(skipping: existingIds)
    }

    func nextUnusedUrl(for requestId: JSONRPCRequestId) -> URL? {
        let usedUrls = requestAttempts[requestId] ?? Set()
        return urls.first { !usedUrls.contains($0) }
    }

    func hasNotUsedUrls(for requestId: JSONRPCRequestId) -> Bool {
        nextUnusedUrl(for: requestId) != nil
    }

    func storeUsedUrl(_ url: URL, for requestId: JSONRPCRequestId) {
        var usedUrls = requestAttempts[requestId] ?? Set()
        usedUrls.insert(url)

        requestAttempts[requestId] = usedUrls
    }

    func clearAttempts(for requestId: JSONRPCRequestId) {
        requestAttempts[requestId] = nil
    }

    func resendRequest(_ request: JSONRPCRequest) {
        guard let nextUrl = nextUnusedUrl(for: request.requestId) else {
            return
        }

        send(
            request: request,
            url: nextUrl,
            timeout: timeout,
            encoder: requestFactory.jsonEncoder,
            decoder: requestFactory.jsonDecoder
        )
    }

    func shouldRetryRequest(_ request: JSONRPCRequest, result: Result<[Response], Error>?) -> Bool {
        guard request.options.resendOnReconnect else {
            return false
        }

        switch result {
        case let .success(responses):
            guard let customNodeSwitcher = customNodeSwitcher else {
                return false
            }

            let hasErrorToRetry = responses.contains { response in
                guard let error = response.basicInfo.error, let identifier = response.basicInfo.identifier else {
                    return false
                }

                return customNodeSwitcher.shouldInterceptAndSwitchNode(for: error, identifier: identifier)
            }

            return hasErrorToRetry && hasNotUsedUrls(for: request.requestId)
        case .failure:
            return hasNotUsedUrls(for: request.requestId)
        case .none:
            return false
        }
    }

    func createRequestFactory(request: JSONRPCRequest, url: URL, timeout: TimeInterval) -> BlockNetworkRequestFactory {
        BlockNetworkRequestFactory {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = HttpMethod.post.rawValue

            urlRequest.httpBody = request.data
            urlRequest.setValue(HttpContentType.json.rawValue, forHTTPHeaderField: HttpHeaderKey.contentType.rawValue)
            urlRequest.timeoutInterval = timeout

            return urlRequest
        }
    }

    func createResultFactory(
        for request: JSONRPCRequest,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) -> AnyNetworkResultFactory<[Response]> {
        AnyNetworkResultFactory { data in
            switch request.requestId {
            case .batch:
                let responseList = try decoder.decode([JSON].self, from: data)

                return try responseList.map { jsonResponse in
                    let basicInfo = try jsonResponse.map(to: JSONRPCBasicData.self)
                    let originalData = try encoder.encode(jsonResponse)

                    return .init(basicInfo: basicInfo, originalData: originalData)
                }
            case .single:
                let basicInfo = try decoder.decode(JSONRPCBasicData.self, from: data)
                let response = Response(basicInfo: basicInfo, originalData: data)

                return [response]
            }
        }
    }

    func notifyResponseHandler(_ responseHandler: JSONRPCResponseHandling, response: Response) {
        if let identifier = response.basicInfo.identifier {
            if let error = response.basicInfo.error {
                responseHandler.handle(error: error, for: identifier)
            } else {
                responseHandler.handle(data: response.originalData, for: identifier)
            }
        }
    }

    func notifyResponseHandler(_ responseHandler: JSONRPCResponseHandling, error: Error, requestId: JSONRPCRequestId) {
        for identifier in requestId.itemIds {
            responseHandler.handle(error: error, for: identifier)
        }
    }

    func processResult(of operation: NetworkOperation<[Response]>, for request: JSONRPCRequest) {
        guard unbindRequest(request: request, operation: operation) else {
            return
        }

        guard !shouldRetryRequest(request, result: operation.result) else {
            resendRequest(request)
            return
        }

        clearAttempts(for: request.requestId)

        guard let responseHandler = request.responseHandler else {
            return
        }

        switch operation.result {
        case let .success(responses):
            for response in responses {
                notifyResponseHandler(responseHandler, response: response)
            }
        case let .failure(error):
            notifyResponseHandler(responseHandler, error: error, requestId: request.requestId)
        case .none:
            let error = BaseOperationError.unexpectedDependentResult
            notifyResponseHandler(responseHandler, error: error, requestId: request.requestId)
        }
    }

    func send(request: JSONRPCRequest, url: URL, timeout: TimeInterval, encoder: JSONEncoder, decoder: JSONDecoder) {
        let requestFactory = createRequestFactory(request: request, url: url, timeout: timeout)

        let resultFactory = createResultFactory(for: request, encoder: encoder, decoder: decoder)

        let operation = NetworkOperation(requestFactory: requestFactory, resultFactory: resultFactory)

        operation.completionBlock = {
            self.completionQueue.async {
                self.mutex.lock()

                defer {
                    self.mutex.unlock()
                }

                self.processResult(of: operation, for: request)
            }
        }

        bindRequest(request: request, operation: operation)
        storeUsedUrl(url, for: request.requestId)

        operationQueue.addOperation(operation)
    }
}
