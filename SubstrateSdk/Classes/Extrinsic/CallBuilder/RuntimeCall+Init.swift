import Foundation

public extension RuntimeCall {
    init(path: CallCodingPath, args: T) {
        self.init(moduleName: path.moduleName, callName: path.callName, args: args)
    }

    var path: CallCodingPath {
        CallCodingPath(moduleName: moduleName, callName: callName)
    }

    func anyRuntimeCall(with context: RuntimeJsonContext?) throws -> AnyRuntimeCall {
        let anyArgs = try args.toScaleCompatibleJSON(with: context?.toRawContext())

        return AnyRuntimeCall(
            moduleName: moduleName,
            callName: callName,
            args: anyArgs
        )
    }
}

public extension RuntimeCall where T == NoRuntimeArgs {
    init(path: CallCodingPath) {
        self.init(moduleName: path.moduleName, callName: path.callName)
    }
}

public typealias AnyRuntimeCall = RuntimeCall<JSON>

public extension AnyRuntimeCall {
    init(path: CallCodingPath, args: some Codable, context: RuntimeJsonContext?) throws {
        let anyArgs = try args.toScaleCompatibleJSON(with: context?.toRawContext())
        self.init(moduleName: path.moduleName, callName: path.callName, args: anyArgs)
    }
}
