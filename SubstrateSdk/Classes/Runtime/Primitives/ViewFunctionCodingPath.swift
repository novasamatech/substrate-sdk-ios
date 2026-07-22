import Foundation

public struct ViewFunctionCodingPath: Equatable {
    public let moduleName: String
    public let functionName: String
    
    public init(moduleName: String, functionName: String) {
        self.moduleName = moduleName
        self.functionName = functionName
    }
}
