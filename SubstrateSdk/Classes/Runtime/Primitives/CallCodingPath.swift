import Foundation

public struct CallCodingPath: Hashable, Codable {
    let moduleName: String
    let callName: String
    
    public init(moduleName: String, callName: String) {
        self.moduleName = moduleName
        self.callName = callName
    }
}
