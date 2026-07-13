import Foundation
import Operation_iOS
import Starscream

extension WebSocketEngine: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client _: WebSocket) {
        mutex.lock()

        switch event {
        case let .binary(data):
            handleBinaryEvent(data: data)
        case let .text(string):
            handleTextEvent(string: string)
        case .connected:
            handleConnectedEvent()
        case let .disconnected(reason, code):
            handleDisconnectedEvent(reason: reason, code: code)
        case let .ping(data):
            handlePing(data: data)
        case let .pong(data):
            handlePong(data: data)
        case let .viabilityChanged(isViable):
            handleViabilityChanged(isViable)
        case let .reconnectSuggested(isSuggested):
            handleReconnectSuggested(isSuggested)
        case let .error(error):
            handleErrorEvent(error)
        case .cancelled:
            handleCancelled()
        @unknown default:
            logger?.warning("(\(chainName):\(selectedURL)) Unhandled event \(event)")
        }

        mutex.unlock()
    }

    private func handleCancelled() {
        logger?.warning("(\(chainName):\(selectedURL)) Remote cancelled")

        switch state {
        case .connecting:
            forceConnectionReset()

            let attempt = reconnectionAttempts[selectedURL] ?? 0
            scheduleReconnectionOrDisconnect(attempt + 1)
        case .connected:
            let cancelled = resetInProgress()

            stopHealthMonitoring()

            forceConnectionReset()
            scheduleReconnectionOrDisconnect(1)

            notify(
                cancelled: cancelled,
                error: JSONRPCEngineError.clientCancelled
            )
        default:
            break
        }
    }

    private func handleErrorEvent(_ error: Error?) {
        if let error = error {
            logger?.error("(\(chainName):\(selectedURL)) Did receive error: \(error)")
        } else {
            logger?.error("(\(chainName):\(selectedURL)) Did receive unknown error")
        }

        switch state {
        case .connected:
            let cancelled = resetInProgress()

            stopHealthMonitoring()

            connection.disconnect()
            startConnecting(0)

            notify(
                cancelled: cancelled,
                error: JSONRPCEngineError.unknownError
            )
        case .connecting:
            forceConnectionReset()

            let attempt = reconnectionAttempts[selectedURL] ?? 0
            scheduleReconnectionOrDisconnect(attempt + 1)
        default:
            break
        }
    }

    private func handleBinaryEvent(data: Data) {
        if let decodedString = String(data: data, encoding: .utf8) {
            logger?.debug("(\(chainName):\(selectedURL)) Did receive data: \(decodedString.prefix(1024))")
        }

        process(data: data)
    }

    private func handleTextEvent(string: String) {
        logger?.debug("(\(chainName):\(selectedURL)) Did receive text: \(string.prefix(1024))")
        if let data = string.data(using: .utf8) {
            process(data: data)
        } else {
            logger?.warning("(\(chainName):\(selectedURL)) Unsupported text event: \(string)")
        }
    }

    private func handleConnectedEvent() {
        logger?.debug("(\(chainName):\(selectedURL)) connection established")

        cancelPongTimeout()
        updatePathViability(true)
        clearBetterPathReconnect()

        updateReconnectionAttempts(0, for: selectedURL)
        changeState(.connected(url: selectedURL))
        sendAllPendingRequests()

        schedulePingIfNeeded()
    }

    private func handleDisconnectedEvent(reason: String, code: UInt16) {
        logger?.warning("(\(chainName):\(selectedURL)) Disconnected with code \(code): \(reason)")

        switch state {
        case .connecting:
            let attempt = reconnectionAttempts[selectedURL] ?? 0
            scheduleReconnectionOrDisconnect(attempt + 1)
        case .connected:
            let cancelled = resetInProgress()

            stopHealthMonitoring()

            scheduleReconnectionOrDisconnect(1)

            notify(
                cancelled: cancelled,
                error: JSONRPCEngineError.remoteCancelled
            )
        default:
            break
        }
    }

    private func handlePing(data: Data?) {
        logger?.debug("(\(chainName):\(selectedURL)) Did receive ping: \((data ?? Data()).toHex())")

        switch state {
        case .connected:
            responseWebsocketPong(for: data)
        default:
            logger?.warning("(\(chainName):\(selectedURL)) Ping data received but not connected")
        }
    }

    private func handlePong(data: Data?) {
        logger?.debug("(\(chainName):\(selectedURL)) Did receive pong: \((data ?? Data()).toHex())")

        cancelPongTimeout()
    }

    private func handleViabilityChanged(_ isViable: Bool) {
        logger?.debug("(\(chainName):\(selectedURL)) Connection viability changed: \(isViable)")

        updatePathViability(isViable)
    }

    private func handleReconnectSuggested(_ isSuggested: Bool) {
        guard case .connected = state else {
            return
        }

        guard isSuggested else {
            clearBetterPathReconnect()
            return
        }

        guard !hasNonResendableInFlight else {
            logger?.debug("(\(chainName):\(selectedURL)) Better network path available, waiting for in-flight requests")

            scheduleBetterPathReconnect()
            return
        }

        logger?.debug("(\(chainName):\(selectedURL)) Better network path available, reconnecting")

        restartConnection()
    }
}

extension WebSocketEngine: ReachabilityListenerDelegate {
    public func didChangeReachability(by manager: ReachabilityManagerProtocol) {
        mutex.lock()

        if manager.isReachable, case .waitingReconnection = state {
            logger?.debug("(\(chainName):\(selectedURL)) Network became reachable, retrying connection")

            reconnectionScheduler.cancel()
            startConnecting(0)
        }

        mutex.unlock()
    }
}

extension WebSocketEngine: SchedulerDelegate {
    public func didTrigger(scheduler: SchedulerProtocol) {
        mutex.lock()

        if scheduler === pingScheduler {
            handlePing(scheduler: scheduler)
        } else if scheduler === pongTimeoutScheduler {
            handlePongTimeout()
        } else if scheduler === viabilityTimeoutScheduler {
            handleViabilityTimeout()
        } else {
            handleReconnection(scheduler: scheduler)
        }

        mutex.unlock()
    }

    private func handleReconnection(scheduler _: SchedulerProtocol) {
        logger?.debug("(\(chainName):\(selectedURL)) Did trigger reconnection scheduler")

        if case .waitingReconnection = state {
            let attempt = reconnectionAttempts[selectedURL] ?? 0
            startConnecting(attempt)
        }
    }

    private func handlePing(scheduler _: SchedulerProtocol) {
        schedulePingIfNeeded()
        schedulePongTimeoutIfNeeded()

        connection.callbackQueue.async {
            self.sendPing()
        }
    }

    private func handlePongTimeout() {
        guard case .connected = state, awaitingPong else {
            return
        }

        logger?.warning("(\(chainName):\(selectedURL)) No pong received in \(pongTimeout)s, restarting connection")

        restartConnection()
    }

    private func handleViabilityTimeout() {
        guard case .connected = state, !isPathViable else {
            return
        }

        logger?.warning("(\(chainName):\(selectedURL)) Connection is no longer viable, restarting")

        restartConnection()
    }
}
