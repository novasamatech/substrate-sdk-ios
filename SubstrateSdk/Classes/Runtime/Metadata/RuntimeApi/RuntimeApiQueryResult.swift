import Foundation

public struct RuntimeApiQueryResult {
    public let callName: String
    public let method: RuntimeApiMethodMetadata
    
    public init(callName: String, method: RuntimeApiMethodMetadata) {
        self.callName = callName
        self.method = method
    }
}
