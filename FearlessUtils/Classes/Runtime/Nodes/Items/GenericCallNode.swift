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
        let call = try value.map(to: RuntimeCall<JSON>.self)

        guard let function = runtimeMetadata.getFunction(from: call.moduleName,
                                                         with: call.callName),
              let moduleIndex = runtimeMetadata.getModuleIndex(call.moduleName),
              let callIndex = runtimeMetadata.getCallIndex(in: call.moduleName,
                                                           callName: call.callName) else {
            throw GenericCallNodeError.unexpectedParams
        }

        guard let args = call.args.dictValue, function.arguments.count == args.count else {
            throw GenericCallNodeError.unexpectedParams
        }

        try encoder.appendU8(json: .stringValue(String(moduleIndex)))
        try encoder.appendU8(json: .stringValue(String(callIndex)))

        for index in 0..<function.arguments.count {
            guard let param = args[function.arguments[index].name] else {
                throw GenericCallNodeError.unexpectedParams
            }

            try encoder.append(json: param, type: function.arguments[index].type)
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let callModuleString = (try decoder.readU8()).stringValue,
              let moduleIndex = Int(callModuleString) else {
            throw GenericCallNodeError.unexpectedDecodedModule
        }

        guard let callFunctionString = (try decoder.readU8()).stringValue,
              let callIndex = Int(callFunctionString) else {
            throw GenericCallNodeError.unexpectedDecodedFunction
        }

        guard let module = runtimeMetadata.modules.first(where: { $0.index == moduleIndex }) else {
            throw GenericCallNodeError.unexpectedCallModule(value: UInt64(moduleIndex))
        }

        guard let calls = module.calls, callIndex < calls.count  else {
            throw GenericCallNodeError.unexpectedCallFunction(value: UInt64(callIndex))
        }

        let call = calls[callIndex]

        let params = try call.arguments.reduce(into: [String: JSON]()) { (result, item) in
            let param = try decoder.read(type: item.type)
            result[item.name] = param
        }

        let result = RuntimeCall(moduleName: module.name, callName: call.name, args: params)

        return try result.toScaleCompatibleJSON()
    }
}
