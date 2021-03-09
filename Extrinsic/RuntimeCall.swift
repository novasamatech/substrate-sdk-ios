import Foundation

public protocol RuntimeCallable: Codable {
    associatedtype Args: Codable

    var moduleName: String { get }
    var callName: String { get }
    var args: Args { get }
}

public struct NoRuntimeArgs: Codable {}

public struct RuntimeCall<T: Codable>: RuntimeCallable {
    public typealias Args = T

    public let moduleName: String
    public let callName: String
    public let args: T

    public init(moduleName: String, callName: String, args: T) {
        self.moduleName = moduleName
        self.callName = callName
        self.args = args
    }
}

public extension RuntimeCall where T == NoRuntimeArgs {
    init(moduleName: String, callName: String) {
        self.moduleName = moduleName
        self.callName = callName
        self.args = NoRuntimeArgs()
    }
}
