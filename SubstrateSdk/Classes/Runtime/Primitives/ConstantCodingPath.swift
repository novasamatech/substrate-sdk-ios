import Foundation

public struct ConstantCodingPath {
    public let moduleName: String
    public let constantName: String
    
    public init(moduleName: String, constantName: String) {
        self.moduleName = moduleName
        self.constantName = constantName
    }
}

public extension ConstantCodingPath {
    static var babeBlockTime: ConstantCodingPath {
        ConstantCodingPath(moduleName: "Babe", constantName: "ExpectedBlockTime")
    }
}
