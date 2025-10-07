import Foundation

public protocol CallDispatchErrorDecoding {
    func decode(
        errorParams: JSON,
        using codingFactory: RuntimeCoderFactoryProtocol
    ) -> Substrate.DispatchCallError?
}

enum CallDispatchErrorDecoderError: Error {
    case unsupportedMetadata
    case errorDescriptionNotFound
}

public final class CallDispatchErrorDecoder {
    let logger: SDKLoggerProtocol?

    public init(logger: SDKLoggerProtocol?) {
        self.logger = logger
    }
}

private extension CallDispatchErrorDecoder {
    func decode(
        moduleError: DispatchError.Module,
        codingFactory: RuntimeCoderFactoryProtocol
    ) throws -> Substrate.DispatchCallError.ModuleDisplayError {
        guard let pallets = (codingFactory.metadata as? PostV14RuntimeMetadataProtocol)?.postV14Pallets else {
            throw CallDispatchErrorDecoderError.unsupportedMetadata
        }

        guard
            let pallet = pallets.first(where: { $0.index == moduleError.index }),
            let errorType = pallet.errors?.type else {
            throw CallDispatchErrorDecoderError.errorDescriptionNotFound
        }

        let decoder = try codingFactory.createDecoder(from: moduleError.error)
        let errorName: ErrorName = try decoder.read(of: String(errorType))

        return Substrate.DispatchCallError.ModuleDisplayError(
            moduleName: pallet.name,
            errorName: errorName.name
        )
    }
}

private extension CallDispatchErrorDecoder {
    struct ErrorName: Decodable {
        let name: String

        init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()

            name = try container.decode(String.self)
        }
    }

    struct FailedEventParams: Decodable {
        let dispatchError: DispatchError

        init(from decoder: Decoder) throws {
            var unkeyedContainer = try decoder.unkeyedContainer()

            dispatchError = try unkeyedContainer.decode(DispatchError.self)
        }
    }

    enum DispatchError: Decodable, Error {
        struct Module: Decodable {
            @StringCodable var index: UInt8
            @BytesCodable var error: Data
        }

        case module(Module)
        case other(String, String?)

        init(from decoder: Decoder) throws {
            var unkeyedContainer = try decoder.unkeyedContainer()

            let module = try unkeyedContainer.decode(String.self)

            switch module {
            case "Module":
                let moduleError = try unkeyedContainer.decode(Module.self)
                self = .module(moduleError)
            default:
                let reason = try? unkeyedContainer.decode(ErrorName.self).name
                self = .other(module, reason)
            }
        }
    }
}

extension CallDispatchErrorDecoder: CallDispatchErrorDecoding {
    public func decode(
        errorParams: JSON,
        using codingFactory: RuntimeCoderFactoryProtocol
    ) -> Substrate.DispatchCallError? {
        do {
            let rawDispatchError = try errorParams.map(
                to: FailedEventParams.self,
                with: codingFactory.createRuntimeJsonContext().toRawContext()
            )

            switch rawDispatchError.dispatchError {
            case let .module(module):
                let displayError = try decode(moduleError: module, codingFactory: codingFactory)

                let rawError = Substrate.DispatchCallError.ModuleRawError(
                    moduleIndex: module.index,
                    error: module.error
                )

                let moduleError = Substrate.DispatchCallError.ModuleError(raw: rawError, display: displayError)

                return Substrate.DispatchCallError.module(moduleError)
            case let .other(module, reason):
                return .other(.init(module: module, reason: reason))
            }
        } catch {
            logger?.error("Error: \(error)")

            return nil
        }
    }
}
