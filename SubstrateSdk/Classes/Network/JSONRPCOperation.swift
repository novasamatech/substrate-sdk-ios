import Foundation
import Operation_iOS

enum JSONRPCOperationError: Error {
    case timeout
}

public class JSONRPCOperation<P: Encodable, T: Decodable>: BaseOperation<T> {
    struct PendingRequest {
        let requestId: UInt16
        let callback: (Result<T, Error>) -> Void
    }

    public let engine: JSONRPCEngine
    public let method: String
    public var parameters: P?
    public let timeout: Int

    private let mutex = NSLock()

    private var pendingRequest: PendingRequest?
    private var scheduler: SchedulerProtocol?

    public init(engine: JSONRPCEngine, method: String, parameters: P? = nil, timeout: Int = 10) {
        self.engine = engine
        self.method = method
        self.parameters = parameters
        self.timeout = timeout

        super.init()
    }

    override public func performAsync(_ callback: @escaping (Result<T, Error>) -> Void) throws {
        mutex.lock()

        defer {
            mutex.unlock()
        }

        let requestId = try engine.callMethod(method, params: parameters) { (result: Result<T, Error>) in
            self.mutex.lock()

            guard self.pendingRequest != nil else {
                return
            }

            self.pendingRequest = nil
            self.clearScheduler()

            if
                case let .failure(error) = result,
                let jsonRPCEngineError = error as? JSONRPCEngineError,
                jsonRPCEngineError == .clientCancelled {
                return
            }

            self.mutex.unlock()

            callback(result)
        }

        if isExecuting {
            pendingRequest = .init(requestId: requestId, callback: callback)
            startScheduler(for: timeout)
        }
    }

    override public func cancel() {
        mutex.lock()

        clearScheduler()

        cancelRequest()

        pendingRequest = nil

        mutex.unlock()

        super.cancel()
    }

    private func cancelRequest() {
        if let requestId = pendingRequest?.requestId {
            engine.cancelForIdentifier(requestId)
        }
    }

    private func startScheduler(for timeout: Int) {
        scheduler = Scheduler(with: self)
        scheduler?.notifyAfter(TimeInterval(timeout))
    }

    private func clearScheduler() {
        scheduler?.cancel()
        scheduler = nil
    }
}

extension JSONRPCOperation: SchedulerDelegate {
    func didTrigger(scheduler _: SchedulerProtocol) {
        mutex.lock()

        scheduler = nil
        cancelRequest()

        let closure = pendingRequest?.callback
        pendingRequest = nil

        mutex.unlock()

        closure?(.failure(JSONRPCOperationError.timeout))
    }
}

public final class JSONRPCListOperation<T: Decodable>: JSONRPCOperation<[String], T> {}
