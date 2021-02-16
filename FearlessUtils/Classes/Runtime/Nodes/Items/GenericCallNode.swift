import Foundation

public enum GenericCallNodeError: Error {
    case unexpectedParams
    case unexpectedCallModule(value: UInt64)
    case unexpectedCallFunction(value: UInt64)
    case argumentsNotMatchingParams(arguments: [String], params: [JSON])
    case unexpectedDecodedModule
    case unexpectedDecodedFunction
}

public struct GenericCallNode: Node {
    public var typeName: String { GenericType.call.name }
    public let runtimeMetadata: RuntimeMetadata

    public init(runtimeMetadata: RuntimeMetadata) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let input = value.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: value)
        }

        guard
            input.count == 3,
            let callModule = input[0].unsignedIntValue,
            let callFunction = input[1].unsignedIntValue,
            let params = input[2].arrayValue else {
            throw GenericCallNodeError.unexpectedParams
        }

        guard let module = runtimeMetadata.modules.first(where: { $0.index == callModule} ) else {
            throw GenericCallNodeError.unexpectedCallModule(value: callModule)
        }

        guard let calls = module.calls, calls.count > callFunction else {
            throw GenericCallNodeError.unexpectedCallFunction(value: callFunction)
        }

        let arguments = calls[Int(callFunction)].arguments.map { $0.type }

        guard arguments.count == params.count else {
            throw GenericCallNodeError.argumentsNotMatchingParams(arguments: arguments,
                                                                  params: params)
        }

        try encoder.appendU8(json: .stringValue(String(callModule)))
        try encoder.appendU8(json: .stringValue(String(callFunction)))

        for index in 0..<arguments.count {
            try encoder.append(json: params[index], type: arguments[index])
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let callModuleString = (try decoder.readU8()).stringValue,
              let callModule = UInt8(callModuleString) else {
            throw GenericCallNodeError.unexpectedDecodedModule
        }

        guard let callFunctionString = (try decoder.readU8()).stringValue,
              let callFunction = UInt8(callFunctionString) else {
            throw GenericCallNodeError.unexpectedDecodedFunction
        }

        guard let module = runtimeMetadata.modules.first(where: { $0.index == callModule} ) else {
            throw GenericCallNodeError.unexpectedCallModule(value: UInt64(callModule))
        }

        guard let calls = module.calls, calls.count > callFunction else {
            throw GenericCallNodeError.unexpectedCallFunction(value: UInt64(callFunction))
        }

        let arguments = calls[Int(callFunction)].arguments.map { $0.type }

        let params: [JSON] = try arguments.map { try decoder.read(type: $0)}

        return .arrayValue([
            .unsignedIntValue(UInt64(callModule)),
            .unsignedIntValue(UInt64(callFunction)),
            .arrayValue(params)
        ])
    }
}
