import Foundation

public struct CallCodingPath: Hashable, Codable {
    public let moduleName: String
    public let callName: String
    
    public init(moduleName: String, callName: String) {
        self.moduleName = moduleName
        self.callName = callName
    }
}
