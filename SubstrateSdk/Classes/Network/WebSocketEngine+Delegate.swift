import Foundation
import Starscream

extension WebSocketEngine: WebSocketDelegate {
    public func didReceive(event: WebSocketEvent, client _: WebSocketClient) {
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
        case let .error(error):
            handleErrorEvent(error)
        case .cancelled:
            handleCancelled()
        default:
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
            let cancelledRequests = resetInProgress()

            pingScheduler.cancel()

            forceConnectionReset()
            scheduleReconnectionOrDisconnect(1)

            notify(
                requests: cancelledRequests,
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
            let cancelledRequests = resetInProgress()

            pingScheduler.cancel()

            connection.disconnect()
            startConnecting(0)

            notify(
                requests: cancelledRequests,
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

        updateReconnectionAttempts(0, for: selectedURL)
        changeState(.connected)
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
            let cancelledRequests = resetInProgress()

            pingScheduler.cancel()

            scheduleReconnectionOrDisconnect(1)

            notify(
                requests: cancelledRequests,
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
    func didTrigger(scheduler: SchedulerProtocol) {
        mutex.lock()

        if scheduler === pingScheduler {
            handlePing(scheduler: scheduler)
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

        connection.callbackQueue.async {
            self.sendPing()
        }
    }
}
