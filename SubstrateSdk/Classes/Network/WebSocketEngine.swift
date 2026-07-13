import Foundation
import Operation_iOS
import Starscream
import SDKLogger

public protocol WebSocketConnectionProtocol: WebSocketClient {
    var callbackQueue: DispatchQueue { get }
    var delegate: WebSocketDelegate? { get set }

    func forceDisconnect()
}

extension WebSocket: WebSocketConnectionProtocol {}

public protocol WebSocketEngineDelegate: AnyObject {
    func webSocketDidChangeState(
        _ connection: AnyObject,
        from oldState: WebSocketEngine.State,
        to newState: WebSocketEngine.State
    )

    func webSocketDidSwitchURL(
        _ connection: AnyObject,
        newUrl: URL
    )
}

public final class WebSocketEngine {
    public enum State: Equatable {
        case notConnected(url: URL?)
        case connecting(url: URL)
        case waitingReconnection(url: URL)
        case connected(url: URL)
    }

    public private(set) var urls: [URL]
    public private(set) var connection: WebSocketConnectionProtocol
    public let connectionFactory: WebSocketConnectionFactoryProtocol
    public let name: String?
    public let logger: SDKLoggerProtocol?
    public let reachabilityManager: ReachabilityManagerProtocol?
    public let customNodeSwitcher: JSONRPCNodeSwitching?
    public let completionQueue: DispatchQueue
    public let processingQueue: DispatchQueue
    public let pingInterval: TimeInterval
    public let connectionTimeout: TimeInterval
    public let pongTimeout: TimeInterval
    public let viabilityTimeout: TimeInterval

    public private(set) var state: State = .notConnected(url: nil) {
        didSet {
            if let delegate = delegate {
                let oldState = oldValue
                let newState = state

                completionQueue.async {
                    delegate.webSocketDidChangeState(self, from: oldState, to: newState)
                }
            }
        }
    }

    internal let mutex = NSLock()

    internal let requestFactory: JSONRPCRequestFactory

    private var jsonDecoder: JSONDecoder {
        requestFactory.jsonDecoder
    }

    private var jsonEncoder: JSONEncoder {
        requestFactory.jsonEncoder
    }

    private let reconnectionStrategy: ReconnectionStrategyProtocol?

    let healthCheckMethod: HealthCheckMethod

    private(set) lazy var reconnectionScheduler: SchedulerProtocol = {
        let scheduler = Scheduler(with: self, callbackQueue: processingQueue)
        return scheduler
    }()

    private(set) lazy var pingScheduler: SchedulerProtocol = {
        let scheduler = Scheduler(with: self, callbackQueue: processingQueue)
        return scheduler
    }()

    private(set) lazy var pongTimeoutScheduler: SchedulerProtocol = {
        let scheduler = Scheduler(with: self, callbackQueue: processingQueue)
        return scheduler
    }()

    private(set) lazy var viabilityTimeoutScheduler: SchedulerProtocol = {
        let scheduler = Scheduler(with: self, callbackQueue: processingQueue)
        return scheduler
    }()

    public var chainName: String { name ?? "unknown" }

    private(set) var pendingRequests: [JSONRPCRequest] = []
    private(set) var inProgressRequests: [UInt16: JSONRPCRequest] = [:]
    private(set) var partialBatches: [String: [JSONRPCBatchRequestItem]] = [:]
    private(set) var subscriptions: [UInt16: JSONRPCSubscribing] = [:]
    private(set) var pendingSubscriptionResponses: [String: [Data]] = [:]
    private(set) var selectedURLIndex: Int
    private(set) var reconnectionAttempts: [URL: Int] = [:]
    private(set) var pendingBetterPathReconnect: Bool = false
    private(set) var awaitingPong: Bool = false
    private(set) var isPathViable: Bool = true
    public var selectedURL: URL { urls[selectedURLIndex] }

    public weak var delegate: WebSocketEngineDelegate?

    public init?(
        urls: [URL],
        connectionFactory: WebSocketConnectionFactoryProtocol = WebSocketConnectionFactory(),
        customNodeSwitcher: JSONRPCNodeSwitching? = nil,
        reachabilityManager: ReachabilityManagerProtocol? = nil,
        reconnectionStrategy: ReconnectionStrategyProtocol? = ExponentialReconnection(),
        healthCheckMethod: HealthCheckMethod = .websocketPingPong,
        version: String = "2.0",
        processingQueue: DispatchQueue? = nil,
        autoconnect: Bool = true,
        connectionTimeout: TimeInterval = 10.0,
        pingInterval: TimeInterval = 30,
        pongTimeout: TimeInterval = 10,
        viabilityTimeout: TimeInterval = 2,
        name: String? = nil,
        logger: SDKLoggerProtocol? = nil
    ) {
        self.connectionFactory = connectionFactory
        requestFactory = JSONRPCRequestFactory(version: version)
        self.customNodeSwitcher = customNodeSwitcher
        self.logger = logger
        self.reconnectionStrategy = reconnectionStrategy
        self.reachabilityManager = reachabilityManager
        self.healthCheckMethod = healthCheckMethod
        self.name = name
        self.urls = urls
        completionQueue = processingQueue ?? JSONRPCEngineShared.processingQueue
        self.processingQueue = processingQueue ?? JSONRPCEngineShared.processingQueue
        self.pingInterval = pingInterval
        self.connectionTimeout = connectionTimeout
        self.pongTimeout = pongTimeout
        self.viabilityTimeout = viabilityTimeout
        selectedURLIndex = 0

        guard let url = urls.first else {
            return nil
        }

        connection = connectionFactory.createConnection(
            for: url,
            processingQueue: self.processingQueue,
            connectionTimeout: connectionTimeout
        )

        connection.delegate = self

        subscribeToReachabilityStatus()

        if autoconnect {
            connectIfNeeded()
        }
    }

    deinit {
        connection.delegate = nil
        connection.forceDisconnect()

        reconnectionScheduler.cancel()
        pingScheduler.cancel()
        pongTimeoutScheduler.cancel()
        viabilityTimeoutScheduler.cancel()
    }

    public func changeUrls(_ newUrls: [URL]) {
        guard !newUrls.isEmpty else {
            return
        }

        disconnectIfNeeded()

        mutex.lock()

        urls = newUrls
        reconnectionAttempts = [:]
        selectedURLIndex = 0

        connection = connectionFactory.createConnection(
            for: selectedURL,
            processingQueue: processingQueue,
            connectionTimeout: connectionTimeout
        )
        connection.delegate = self

        logger?.debug("(\(chainName)) Did set new urls: \(newUrls)")

        mutex.unlock()

        connectIfNeeded()
    }

    public func connectIfNeeded() {
        mutex.lock()

        switch state {
        case .notConnected:
            startConnecting(0)

            logger?.debug("(\(chainName):\(selectedURL)) Did start connecting to socket")
        case .waitingReconnection:
            reconnectionScheduler.cancel()

            startConnecting(0)

            logger?.debug("(\(chainName):\(selectedURL)) Waiting for connection but decided to connect anyway")
        default:
            logger?.debug("(\(chainName):\(selectedURL)) Already connecting to socket")
        }

        mutex.unlock()
    }

    public func disconnectIfNeeded(_ force: Bool = false) {
        mutex.lock()

        switch state {
        case .connected:
            state = .notConnected(url: selectedURL)

            let cancelled = resetInProgress()

            if force {
                forceConnectionReset()
            } else {
                connection.disconnect(closeCode: CloseCode.goingAway.rawValue)
            }

            notify(
                cancelled: cancelled,
                error: JSONRPCEngineError.clientCancelled
            )

            stopHealthMonitoring()

            logger?.debug("(\(chainName):\(selectedURL)) Did start disconnect from socket")
        case .connecting:
            state = .notConnected(url: selectedURL)

            forceConnectionReset()

            logger?.debug("(\(chainName):\(selectedURL)) Cancel socket connection")

        case .waitingReconnection:
            state = .notConnected(url: selectedURL)

            forceConnectionReset()
            reconnectionScheduler.cancel()

            logger?.debug("(\(chainName):\(selectedURL)) Cancel reconnection scheduler due to disconnection")
        default:
            logger?.debug("(\(chainName):\(selectedURL)) Already disconnected from socket")
        }

        mutex.unlock()
    }
}

// MARK: Internal

extension WebSocketEngine {
    func changeState(_ newState: State) {
        state = newState
    }

    func subscribeToReachabilityStatus() {
        do {
            try reachabilityManager?.add(listener: self)
        } catch {
            logger?.warning("(\(chainName):\(selectedURL)) Failed to subscribe to reachability changes")
        }
    }

    func clearReachabilitySubscription() {
        reachabilityManager?.remove(listener: self)
    }

    func updateConnectionForRequest(_ request: JSONRPCRequest) {
        switch state {
        case .connected:
            send(request: request)
        case .connecting:
            pendingRequests.append(request)
        case .notConnected:
            pendingRequests.append(request)

            startConnecting(0)
        case .waitingReconnection:
            logger?.debug("(\(chainName):\(selectedURL)) Don't wait for reconnection for incoming request")

            pendingRequests.append(request)

            reconnectionScheduler.cancel()

            startConnecting(0)
        }
    }

    func clearPartialBatchStorage(for batchId: JSONRPCBatchId) {
        partialBatches[batchId] = nil
    }

    func storeBatchItem(_ item: JSONRPCBatchRequestItem, for batchId: JSONRPCBatchId) {
        var items = partialBatches[batchId] ?? []
        items.append(item)

        partialBatches[batchId] = items
    }

    func send(request: JSONRPCRequest) {
        // batches results can be returned in different responses, handle them as single requests
        switch request.requestId {
        case let .single(singleId):
            inProgressRequests[singleId] = request
        case let .batch(_, itemIds):
            for itemId in itemIds {
                inProgressRequests[itemId] = request
            }
        }

        connection.write(stringData: request.data, completion: nil)
    }

    func sendAllPendingRequests() {
        let currentPendings = pendingRequests
        pendingRequests = []

        for pending in currentPendings {
            logger?.debug("(\(chainName):\(selectedURL)) Sending request with id: \(pending.requestId)")
            logger?.debug("(\(chainName):\(selectedURL)) \(String(data: pending.data, encoding: .utf8)!)")
            send(request: pending)
        }
    }

    func forceConnectionReset() {
        connection.delegate = nil
        connection.forceDisconnect()

        connection = connectionFactory.createConnection(
            for: selectedURL,
            processingQueue: processingQueue,
            connectionTimeout: connectionTimeout
        )

        connection.delegate = self
    }

    struct CancelledEntities {
        let requests: [JSONRPCRequest]
        let subscriptions: [JSONRPCSubscribing]
    }

    func resetInProgress() -> CancelledEntities {
        // we can have batches decomposed by single requests
        let inProgressWithoutDuplicates = inProgressRequests.values.reduce(into: [JSONRPCRequestId: JSONRPCRequest]()) {
            $0[$1.requestId] = $1
        }

        let idempotentRequests: [JSONRPCRequest] = inProgressWithoutDuplicates.compactMap {
            $1.options.resendOnReconnect ? $1 : nil
        }

        let notifiableRequests = inProgressWithoutDuplicates.compactMap {
            !$1.options.resendOnReconnect && $1.responseHandler != nil ? $1 : nil
        }

        pendingRequests.append(contentsOf: idempotentRequests)
        inProgressRequests = [:]

        let cancelledSubscriptions = resetActiveSubscriptions()

        return CancelledEntities(requests: notifiableRequests, subscriptions: cancelledSubscriptions)
    }

    func resetActiveSubscriptions() -> [JSONRPCSubscribing] {
        let allSubscriptions = Array(subscriptions.values)

        let nonIdempotentSubscriptions = allSubscriptions.filter { !$0.requestOptions.resendOnReconnect }

        for subscription in nonIdempotentSubscriptions {
            subscriptions.removeValue(forKey: subscription.requestId)
        }

        // remoteId != nil ⇒ acknowledged; not-yet-acked subs resubscribe via their in-flight request
        let resendableSubscriptions = allSubscriptions.filter {
            $0.requestOptions.resendOnReconnect && $0.remoteId != nil
        }

        for subscription in resendableSubscriptions {
            subscription.remoteId = nil
        }

        let subscriptionRequests: [JSONRPCRequest] = resendableSubscriptions.map {
            JSONRPCRequest(
                requestId: .single($0.requestId),
                data: $0.requestData,
                options: $0.requestOptions,
                responseHandler: nil
            )
        }

        pendingRequests.append(contentsOf: subscriptionRequests)

        return nonIdempotentSubscriptions
    }

    func process(data: Data) {
        do {
            if let response = try? jsonDecoder.decode(JSONRPCBasicData.self, from: data) {
                // handle single request or subscription
                if let identifier = response.identifier {
                    if let error = response.error {
                        processErrorAndResetIfNeeded(for: identifier, error: error)
                    } else {
                        completeRequestForRemoteId(identifier, data: data)
                    }
                } else {
                    try processSubscriptionUpdate(data)
                }
            } else {
                // handle batch response

                let batchResponses = try jsonDecoder.decode([JSON].self, from: data)

                let singleItemResponses = try batchResponses.reduce(into: [UInt16: Data]()) { accum, response in
                    // ignore undefined responses without ids
                    guard let identifier = response.id?.unsignedIntValue else {
                        logger?.error(
                            "(\(chainName):\(selectedURL)) Batch item id is missing, this should normally not happen"
                        )
                        return
                    }

                    // ignore error as we proccess them separately
                    guard response.error?.dictValue == nil else {
                        return
                    }

                    accum[UInt16(identifier)] = try jsonEncoder.encode(response)
                }

                for singleItemResponse in singleItemResponses {
                    completeRequestForRemoteId(singleItemResponse.key, data: singleItemResponse.value)
                }

                processErrorsInBatch(responses: batchResponses)
            }
        } catch {
            if let stringData = String(data: data, encoding: .utf8) {
                logger?.error("(\(chainName):\(selectedURL)) Can't parse data: \(stringData)")
            } else {
                logger?.error("(\(chainName):\(selectedURL)) Can't parse data")
            }
        }

        completeBetterPathReconnectIfNeeded()
    }

    @discardableResult
    func processErrorsInBatch(responses: [JSON]) -> Bool {
        for jsonResponse in responses {
            if
                let errorJson = jsonResponse.error,
                let error = try? errorJson.map(to: JSONRPCError.self),
                let identifier = jsonResponse.id?.unsignedIntValue {
                if processErrorAndResetIfNeeded(for: UInt16(identifier), error: error) {
                    return true
                }
            }
        }

        return false
    }

    @discardableResult
    func processErrorAndResetIfNeeded(for identifier: UInt16, error: JSONRPCError) -> Bool {
        if
            let customNodeSwitcher = customNodeSwitcher,
            customNodeSwitcher.shouldInterceptAndSwitchNode(for: error, identifier: identifier) {
            resetRequestsAndSwitchNode()

            return true
        } else {
            completeRequestForRemoteId(identifier, error: error)

            return false
        }
    }

    func addSubscription(_ subscription: JSONRPCSubscribing) {
        subscriptions[subscription.requestId] = subscription
    }

    func prepareRequest<P: Encodable, T: Decodable>(
        method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?,
        preGeneratedRequestId: UInt16? = nil
    ) throws -> JSONRPCRequest {
        let requestId = preGeneratedRequestId ?? generateRequestId()

        return try requestFactory.prepareRequest(
            method: method,
            params: params,
            options: options,
            completion: closure,
            idType: .existing(requestId)
        )
    }

    func generateRequestId() -> UInt16 {
        let pendingItems = pendingRequests.flatMap(\.requestId.itemIds) +
            inProgressRequests.map(\.key) +
            Array(subscriptions.keys)
        
        let partialBatches = partialBatches.values.flatMap { batch in
            batch.map(\.requestId)
        }

        let existingIds: Set<UInt16> = Set(pendingItems + partialBatches)

        return requestFactory.generateRequestId(skipping: existingIds)
    }

    func cancelRequestForLocalId(_ identifier: UInt16) {
        if let index = pendingRequests.firstIndex(where: { $0.requestId.itemIds.contains(identifier) }) {
            let request = pendingRequests.remove(at: index)

            notify(
                request: request,
                error: JSONRPCEngineError.clientCancelled,
                identifier: identifier
            )
        } else if let request = inProgressRequests.removeValue(forKey: identifier) {
            notify(
                request: request,
                error: JSONRPCEngineError.clientCancelled,
                identifier: identifier
            )
        }

        // check whether there is subscription for this id and send unsubscribe request

        if let subscription = subscriptions[identifier], let remoteId = subscription.remoteId {
            unsubscribe(for: remoteId, method: subscription.unsubscribeMethod)
        }

        subscriptions[identifier] = nil
    }

    func unsubscribe(for remoteId: String, method: String) {
        pendingSubscriptionResponses[remoteId] = nil

        do {
            let request = try prepareRequest(
                method: method,
                params: [remoteId],
                options: JSONRPCOptions()
            ) { [weak self] (result: Result<Bool, Error>) in
                self?.provideUnsubscriptionResult(result, remoteId: remoteId)
            }

            updateConnectionForRequest(request)
        } catch {
            logger?.error("(\(chainName):\(selectedURL)) Failed to create unsubscription request: \(error)")
        }
    }

    func provideUnsubscriptionResult(_ result: Result<Bool, Error>, remoteId: String) {
        switch result {
        case let .success(isSuccess):
            logger?.debug("(\(chainName):\(selectedURL)) Unsubscription request completed \(remoteId): \(isSuccess)")
        case let .failure(error):
            logger?.error("(\(chainName):\(selectedURL)) Unsubscription request failed \(remoteId): \(error)")
        }
    }

    func completeRequestForRemoteId(_ identifier: UInt16, data: Data) {
        if let request = inProgressRequests.removeValue(forKey: identifier) {
            notify(request: request, data: data, identifier: identifier)
        }

        if subscriptions[identifier] != nil {
            processSubscriptionResponse(identifier, data: data)
        }
    }

    func processSubscriptionResponse(_ identifier: UInt16, data: Data) {
        do {
            let response = try jsonDecoder.decode(JSONRPCData<JSONRPCSubscriptionId>.self, from: data)
            let remoteId = response.result.wrappedValue
            subscriptions[identifier]?.remoteId = remoteId

            logger?.debug("(\(chainName):\(selectedURL)) Did receive subscription id: \(remoteId)")

            if let pendingResponses = pendingSubscriptionResponses[remoteId] {
                pendingSubscriptionResponses[remoteId] = nil

                try pendingResponses.forEach { try processSubscriptionUpdate($0) }
            }
        } catch {
            processSubscriptionError(identifier, error: error, shouldUnsubscribe: true)

            if let responseString = String(data: data, encoding: .utf8) {
                logger?.error("(\(chainName):\(selectedURL)) Did fail to parse subscription data: \(responseString)")
            } else {
                logger?.error("(\(chainName):\(selectedURL)) Did fail to parse subscription data")
            }
        }
    }

    func processSubscriptionUpdate(_ data: Data) throws {
        let basicResponse = try jsonDecoder.decode(
            JSONRPCSubscriptionBasicUpdate.self,
            from: data
        )
        let remoteId = basicResponse.params.subscription

        if let (_, subscription) = subscriptions
            .first(where: { $1.remoteId == remoteId }) {
            logger?.debug("Did receive update for subscription: \(remoteId)")

            completionQueue.async {
                try? subscription.handle(data: data)
            }
        } else {
            logger?.warning("No handler for subscription: \(remoteId). Saving pending response...")

            var responses = pendingSubscriptionResponses[remoteId] ?? []
            responses.append(data)

            pendingSubscriptionResponses[remoteId] = responses
        }
    }

    func completeRequestForRemoteId(_ identifier: UInt16, error: Error) {
        if let request = inProgressRequests.removeValue(forKey: identifier) {
            notify(request: request, error: error, identifier: identifier)
        }

        if subscriptions[identifier] != nil {
            processSubscriptionError(identifier, error: error, shouldUnsubscribe: true)
        }
    }

    func processSubscriptionError(_ identifier: UInt16, error: Error, shouldUnsubscribe: Bool) {
        if let subscription = subscriptions[identifier] {
            if shouldUnsubscribe {
                subscriptions.removeValue(forKey: identifier)
            }

            processingQueue.async {
                subscription.handle(error: error, unsubscribed: shouldUnsubscribe)
            }
        }
    }

    func notify(request: JSONRPCRequest, data: Data, identifier: UInt16) {
        completionQueue.async {
            request.responseHandler?.handle(data: data, for: identifier)
        }
    }

    func notify(requests: [JSONRPCRequest], error: Error) {
        requests.forEach { request in
            request.requestId.itemIds.forEach { identifier in
                notify(request: request, error: error, identifier: identifier)
            }
        }
    }

    func notify(cancelled: CancelledEntities, error: Error) {
        notify(requests: cancelled.requests, error: error)

        cancelled.subscriptions.forEach { subscription in
            completionQueue.async {
                subscription.handle(error: error, unsubscribed: true)
            }
        }
    }

    func notify(request: JSONRPCRequest, error: Error, identifier: UInt16) {
        completionQueue.async {
            request.responseHandler?.handle(error: error, for: identifier)
        }
    }

    func updateReconnectionAttempts(_ newValue: Int, for url: URL) {
        reconnectionAttempts[url] = newValue

        logger?.debug("(\(chainName):\(url)) Did set reconnection attempts to \(newValue) for url \(url)")
    }

    func scheduleReconnectionOrDisconnect(_ attempt: Int, after error: Error? = nil) {
        let actualAttempt: Int
        if attempt > 1 {
            logger?.warning("(\(chainName):\(selectedURL)) Looks like node is down trying another one...")

            // looks like node is down try another one
            actualAttempt = switchNode()
        } else {
            actualAttempt = attempt
        }

        updateReconnectionAttempts(actualAttempt, for: selectedURL)

        if let reconnectionStrategy = reconnectionStrategy,
           let nextDelay = reconnectionStrategy.reconnectAfter(attempt: actualAttempt) {
            state = .waitingReconnection(url: selectedURL)

            let chainName = "\(chainName):\(selectedURL)"
            logger?.debug(
                "(\(chainName) Schedule reconnection with attempt \(actualAttempt) and delay \(nextDelay)"
            )

            reconnectionScheduler.notifyAfter(nextDelay)
        } else {
            state = .notConnected(url: selectedURL)

            // notify pendings about error because there is no chance to reconnect

            let requests = pendingRequests
            pendingRequests = []

            let requestError = error ?? JSONRPCEngineError.unknownError
            notify(requests: requests, error: requestError)
        }
    }

    func resetRequestsAndSwitchNode() {
        let cancelled = resetInProgress()

        stopHealthMonitoring()

        let reconnectionAttempt = switchNode()
        startConnecting(reconnectionAttempt)

        notify(cancelled: cancelled, error: JSONRPCEngineError.unknownError)
    }

    func switchNode() -> Int {
        logger?.warning("(\(chainName):\(selectedURL)) Switching node urls...")

        connection.delegate = nil
        connection.forceDisconnect()

        selectedURLIndex = (selectedURLIndex + 1) % urls.count
        connection = connectionFactory.createConnection(
            for: selectedURL,
            processingQueue: processingQueue,
            connectionTimeout: connectionTimeout
        )

        connection.delegate = self

        let actualAttempt = (reconnectionAttempts[selectedURL] ?? 0) + 1

        if urls.count > 1 {
            let currentURL = selectedURL
            completionQueue.async {
                self.delegate?.webSocketDidSwitchURL(self, newUrl: currentURL)
            }
        }

        return actualAttempt
    }

    func schedulePingIfNeeded() {
        guard pingInterval > 0.0, case .connected = state else {
            return
        }

        logger?.debug("(\(chainName):\(selectedURL)) Schedule socket ping")

        pingScheduler.notifyAfter(pingInterval)
    }

    func schedulePongTimeoutIfNeeded() {
        guard pongTimeout > 0.0, case .connected = state, !awaitingPong else {
            return
        }

        awaitingPong = true
        pongTimeoutScheduler.notifyAfter(pongTimeout)
    }

    func cancelPongTimeout() {
        awaitingPong = false
        pongTimeoutScheduler.cancel()
    }

    func updatePathViability(_ isViable: Bool) {
        isPathViable = isViable

        if isViable {
            viabilityTimeoutScheduler.cancel()
        } else if viabilityTimeout > 0.0, case .connected = state {
            viabilityTimeoutScheduler.notifyAfter(viabilityTimeout)
        }
    }

    func stopHealthMonitoring() {
        pingScheduler.cancel()
        cancelPongTimeout()

        isPathViable = true
        viabilityTimeoutScheduler.cancel()
    }

    func restartConnection() {
        clearBetterPathReconnect()

        let cancelled = resetInProgress()

        stopHealthMonitoring()
        forceConnectionReset()
        startConnecting(0)

        notify(cancelled: cancelled, error: JSONRPCEngineError.remoteCancelled)
    }

    var hasNonResendableInFlight: Bool {
        inProgressRequests.contains { !$0.value.options.resendOnReconnect } ||
            subscriptions.contains { !$0.value.requestOptions.resendOnReconnect }
    }

    func scheduleBetterPathReconnect() {
        pendingBetterPathReconnect = true
    }

    func clearBetterPathReconnect() {
        pendingBetterPathReconnect = false
    }

    func completeBetterPathReconnectIfNeeded() {
        guard pendingBetterPathReconnect, case .connected = state, !hasNonResendableInFlight else {
            return
        }

        pendingBetterPathReconnect = false

        logger?.debug("(\(chainName):\(selectedURL)) In-flight requests finished, reconnecting to better network path")

        restartConnection()
    }

    func sendPing() {
        guard case .connected = state else {
            logger?.warning("(\(chainName):\(selectedURL)) Tried to send ping but not connected")
            return
        }

        logger?.debug("(\(chainName):\(selectedURL)) Sending socket ping")

        do {
            switch healthCheckMethod {
            case .substrate:
                try sendSubstratePing()
            case .websocketPingPong:
                sendWebsocketPing()
            }
        } catch {
            mutex.lock()
            cancelPongTimeout()
            mutex.unlock()

            logger?.error("(\(chainName)) Did receive ping error: \(error)")
        }
    }

    func sendSubstratePing() throws {
        let options = JSONRPCOptions(resendOnReconnect: false)
        _ = try callMethod(
            RPCMethod.healthCheck,
            params: [String](),
            options: options
        ) { [weak self] (result: Result<SubstrateHealthResult, Error>) in
            self?.handlePing(result: result)
        }
    }

    func sendWebsocketPing() {
        connection.write(ping: Data())
    }

    func responseWebsocketPong(for pingData: Data?) {
        connection.write(pong: pingData ?? Data())
    }

    func handlePing(result: Result<SubstrateHealthResult, Error>) {
        mutex.lock()
        cancelPongTimeout()
        mutex.unlock()

        switch result {
        case let .success(health):
            if health.isSyncing {
                logger?.warning("(\(chainName):\(selectedURL)) Node is not healthy")
            }
        case let .failure(error):
            logger?.error("(\(chainName):\(selectedURL)) Health check error: \(error)")
        }
    }

    func startConnecting(_ attempt: Int) {
        logger?.debug("(\(chainName):\(selectedURL)) Start connecting with attempt: \(attempt)")

        updateReconnectionAttempts(attempt, for: selectedURL)
        state = .connecting(url: selectedURL)

        connection.connect()
    }
}
