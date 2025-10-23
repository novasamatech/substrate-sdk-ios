import Foundation

public struct StateCallPath {
    public let module: String
    public let method: String
    
    public init(module: String, method: String) {
        self.module = module
        self.method = method
    }
}
