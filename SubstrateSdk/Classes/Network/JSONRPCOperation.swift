import Foundation
import RobinHood

enum JSONRPCOperationError: Error {
    case timeout
}

public class JSONRPCOperation<P: Encodable, T: Decodable>: BaseOperation<T> {
    public let engine: JSONRPCEngine
    private(set) var requestId: UInt16?
    public let method: String
    public var parameters: P?
    public let timeout: Int

    public init(engine: JSONRPCEngine, method: String, parameters: P? = nil, timeout: Int = 10) {
        self.engine = engine
        self.method = method
        self.parameters = parameters
        self.timeout = timeout

        super.init()
    }

    public override func main() {
        super.main()

        if isCancelled {
            return
        }

        if result != nil {
            return
        }

        do {
            let semaphore = DispatchSemaphore(value: 0)

            var optionalCallResult: Result<T, Error>?

            requestId = try engine.callMethod(method, params: parameters) { (result: Result<T, Error>) in
                optionalCallResult = result

                semaphore.signal()
            }

            let status = semaphore.wait(timeout: .now() + .seconds(timeout))

            if status == .timedOut {
                result = .failure(JSONRPCOperationError.timeout)
                return
            }

            guard let callResult = optionalCallResult else {
                return
            }

            if
                case let .failure(error) = callResult,
                let jsonRPCEngineError = error as? JSONRPCEngineError,
                jsonRPCEngineError == .clientCancelled {
                return
            }

            switch callResult {
            case let .success(response):
                result = .success(response)
            case let .failure(error):
                result = .failure(error)
            }

        } catch {
            result = .failure(error)
        }
    }

    public override func cancel() {
        if let requestId = requestId {
            engine.cancelForIdentifier(requestId)
        }

        super.cancel()
    }
}

public final class JSONRPCListOperation<T: Decodable>: JSONRPCOperation<[String], T> {}
