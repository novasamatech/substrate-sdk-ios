import Foundation

public struct StorageCodingPath: Equatable {
    public let moduleName: String
    public let itemName: String
    
    public init(moduleName: String, itemName: String) {
        self.moduleName = moduleName
        self.itemName = itemName
    }
}

public extension StorageCodingPath {
    static var timestampNow: StorageCodingPath {
        StorageCodingPath(moduleName: "Timestamp", itemName: "Now")
    }
}
