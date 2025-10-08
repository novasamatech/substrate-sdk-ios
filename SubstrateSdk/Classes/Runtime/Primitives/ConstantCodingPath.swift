import Foundation

public struct ConstantCodingPath {
    public let moduleName: String
    public let constantName: String
}

public extension ConstantCodingPath {
    static var babeBlockTime: ConstantCodingPath {
        ConstantCodingPath(moduleName: "Babe", constantName: "ExpectedBlockTime")
    }
}
