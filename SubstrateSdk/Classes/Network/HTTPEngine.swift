import Foundation
import Operation_iOS

public final class HTTPEngine {
    struct Response {
        let basicInfo: JSONRPCBasicData
        let originalData: Data
    }

    struct ResendAttempt {
        let attempt: Int
        let url: URL
        let scheduler: Scheduler?
        let request: JSONRPCRequest

        static func initial(for url: URL, request: JSONRPCRequest) -> ResendAttempt {
            .init(attempt: 0, url: url, scheduler: nil, request: request)
        }

        func scheduling(attempt: Int, url: URL, scheduler: Scheduler?) -> ResendAttempt {
            .init(
                attempt: attempt,
                url: url,
                scheduler: scheduler,
                request: request
            )
        }
    }

    public private(set) var urls: [URL]

    public let name: String?
    public let logger: SDKLoggerProtocol?
    public let completionQueue: DispatchQueue
    public let operationQueue: OperationQueue
    public let timeout: TimeInterval
    public let customNodeSwitcher: JSONRPCNodeSwitching?
    public let maxAttemptsPerNode: Int
    public let requestModifier: NetworkRequestModifierProtocol?

    public var chainName: String { name ?? "unknown" }

    internal let requestFactory: JSONRPCRequestFactory

    internal let mutex = NSLock()

    private(set) var inProgressRequests: [UInt16: JSONRPCRequestId] = [:]
    private(set) var requestIdMapping: [JSONRPCRequestId: Operation] = [:]
    private(set) var resendAttempts: [JSONRPCRequestId: ResendAttempt] = [:]
    private(set) var partialBatches: [String: [JSONRPCBatchRequestItem]] = [:]
    private let resendStrategy: ReconnectionStrategyProtocol?

    private var selectedURLIndex: Int = 0

    public var selectedURL: URL {
        urls[selectedURLIndex]
    }

    public init?(
        urls: [URL],
        operationQueue: OperationQueue,
        version: String = "2.0",
        resendStrategy: ReconnectionStrategyProtocol? = ExponentialReconnection(),
        maxAttemptsPerNode: Int = 3,
        customNodeSwitcher: JSONRPCNodeSwitching? = nil,
        timeout: TimeInterval = 60,
        completionQueue: DispatchQueue? = nil,
        name: String? = nil,
        requestModifier: NetworkRequestModifierProtocol? = nil,
        logger: SDKLoggerProtocol? = nil
    ) {
        guard !urls.isEmpty else {
            return nil
        }

        self.urls = urls
        requestFactory = JSONRPCRequestFactory(version: version)
        self.completionQueue = completionQueue ?? JSONRPCEngineShared.processingQueue
        self.customNodeSwitcher = customNodeSwitcher
        self.resendStrategy = resendStrategy
        self.maxAttemptsPerNode = maxAttemptsPerNode
        self.operationQueue = operationQueue
        self.timeout = timeout
        self.name = name
        self.requestModifier = requestModifier
        self.logger = logger
    }

    public func changeUrls(_ newUrls: [URL]) {
        guard !newUrls.isEmpty else {
            return
        }

        mutex.lock()

        urls = newUrls
        selectedURLIndex = 0

        logger?.debug("(\(chainName)) Did set new urls: \(newUrls)")

        mutex.unlock()
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

    func unbindResendAttempts(for identifier: UInt16) {
        guard let requestId = resendAttempts.keys.first(where: { $0.itemIds.contains(identifier) }) else {
            return
        }

        clearResendAttempts(for: requestId)
    }

    func clearResendAttempts(for requestId: JSONRPCRequestId) {
        resendAttempts[requestId]?.scheduler?.cancel()
        resendAttempts[requestId] = nil
    }

    func generateRequestId() -> UInt16 {
        let pendingItems = inProgressRequests.keys
        let partialBatches = partialBatches.values.flatMap { batch in
            batch.map(\.requestId)
        }

        let existingIds: Set<UInt16> = Set(pendingItems + partialBatches)

        return requestFactory.generateRequestId(skipping: existingIds)
    }

    func scheduleResend(request: JSONRPCRequest) {
        guard let resendStrategy = resendStrategy else {
            return
        }

        var currentAttempt = resendAttempts[request.requestId] ??
            ResendAttempt.initial(for: selectedURL, request: request)

        let nextAttempt: Int

        if currentAttempt.attempt >= maxAttemptsPerNode - 1, urls.count > 1 {
            // other requests may also change nodes
            if currentAttempt.url == selectedURL {
                selectedURLIndex = (selectedURLIndex + 1) % urls.count
            }

            nextAttempt = 0
        } else {
            nextAttempt = currentAttempt.attempt + 1
        }

        currentAttempt.scheduler?.cancel()

        if let delay = resendStrategy.reconnectAfter(attempt: nextAttempt), delay > 0 {
            logger?.debug("Retrying request \(request.requestId) after \(delay)...")

            let scheduler = currentAttempt.scheduler ?? Scheduler(with: self, callbackQueue: completionQueue)
            currentAttempt = currentAttempt.scheduling(
                attempt: nextAttempt,
                url: selectedURL,
                scheduler: scheduler
            )

            resendAttempts[request.requestId] = currentAttempt

            scheduler.notifyAfter(delay)
        } else {
            currentAttempt = currentAttempt.scheduling(
                attempt: nextAttempt,
                url: selectedURL,
                scheduler: currentAttempt.scheduler
            )

            resendAttempts[request.requestId] = currentAttempt

            resendRequest(currentAttempt)
        }
    }

    func resendRequest(_ attempt: ResendAttempt) {
        logger?.debug("(\(chainName):\(attempt)) retrying request: \(attempt.request)")

        send(
            request: attempt.request,
            url: attempt.url,
            timeout: timeout,
            encoder: requestFactory.jsonEncoder,
            decoder: requestFactory.jsonDecoder
        )
    }

    func shouldRetryRequest(_ request: JSONRPCRequest, result: Result<[Response], Error>?) -> Bool {
        guard request.options.resendOnReconnect, resendStrategy != nil else {
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

            return hasErrorToRetry
        case .failure:
            return true
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

    func processResult(of operation: NetworkOperation<[Response]>, for request: JSONRPCRequest, url: URL) {
        guard unbindRequest(request: request, operation: operation) else {
            return
        }

        guard !shouldRetryRequest(request, result: operation.result) else {
            scheduleResend(request: request)
            return
        }

        clearResendAttempts(for: request.requestId)

        guard let responseHandler = request.responseHandler else {
            return
        }

        logger?.debug("(\(chainName):\(url)) processing result: \(String(describing: operation.result))")

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
        operation.requestModifier = requestModifier

        operation.completionBlock = {
            self.completionQueue.async {
                self.mutex.lock()

                defer {
                    self.mutex.unlock()
                }

                self.processResult(of: operation, for: request, url: url)
            }
        }

        bindRequest(request: request, operation: operation)

        logger?.debug("(\(chainName):\(url)) sending request: \(request)")

        operationQueue.addOperation(operation)
    }
}

extension HTTPEngine: SchedulerDelegate {
    func didTrigger(scheduler: SchedulerProtocol) {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        guard let attempt = resendAttempts.first(where: { $0.value.scheduler === scheduler }) else {
            return
        }

        resendRequest(attempt.value)
    }
}
