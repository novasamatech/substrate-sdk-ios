import Foundation

public enum GenericCallNodeError: Error {
    case unexpectedParams
    case unexpectedCallModule(value: UInt8)
    case unexpectedCallFunction(value: UInt8)
    case argumentsNotMatchingParams(arguments: [String], params: [JSON])
    case unexpectedDecodedModule
    case unexpectedDecodedFunction
}

public class GenericCallNode: Node {
    public var typeName: String { GenericType.call.name }
    public let runtimeMetadata: RuntimeMetadataProtocol

    public init(runtimeMetadata: RuntimeMetadataProtocol) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        if case .stringValue = value {
            // raw call in hex

            try encoder.appendBytes(json: value)
        } else {
            // constructed call

            let callInfo = try value.map(to: RuntimeCall<JSON>.self)

            guard let call = runtimeMetadata.getCall(from: callInfo.moduleName, with: callInfo.callName),
                  let moduleIndex = runtimeMetadata.getModuleIndex(callInfo.moduleName),
                  let callIndex = runtimeMetadata.getCallIndex(
                    in: callInfo.moduleName,
                    callName: callInfo.callName
                  ) else {
                throw GenericCallNodeError.unexpectedParams
            }

            guard let args = callInfo.args.dictValue, call.arguments.count == args.count else {
                throw GenericCallNodeError.unexpectedParams
            }

            try encoder.appendU8(json: .stringValue(String(moduleIndex)))
            try encoder.appendU8(json: .stringValue(String(callIndex)))

            for index in 0..<call.arguments.count {
                guard let param = args[call.arguments[index].name] else {
                    throw GenericCallNodeError.unexpectedParams
                }

                try encoder.append(json: param, type: call.arguments[index].type)
            }
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let callModuleString = (try decoder.readU8()).stringValue,
              let moduleIndex = UInt8(callModuleString) else {
            throw GenericCallNodeError.unexpectedDecodedModule
        }

        guard let callFunctionString = (try decoder.readU8()).stringValue,
              let callIndex = UInt8(callFunctionString) else {
            throw GenericCallNodeError.unexpectedDecodedFunction
        }

        guard let moduleName = runtimeMetadata.getModuleName(by: moduleIndex) else {
            throw GenericCallNodeError.unexpectedCallModule(value: moduleIndex)
        }

        guard let call = runtimeMetadata.getCallByModuleIndex(moduleIndex, callIndex: callIndex) else {
            throw GenericCallNodeError.unexpectedCallFunction(value: callIndex)
        }

        let params = try call.arguments.reduce(into: [String: JSON]()) { (result, item) in
            let param = try decoder.read(type: item.type)
            result[item.name] = param
        }

        let result = RuntimeCall(moduleName: moduleName, callName: call.name, args: params)

        return try result.toScaleCompatibleJSON()
    }
}
