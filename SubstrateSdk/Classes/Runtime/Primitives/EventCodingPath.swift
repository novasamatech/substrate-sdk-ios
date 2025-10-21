import Foundation

public struct EventCodingPath: Equatable, Hashable {
    public let moduleName: String
    public let eventName: String

    public init(moduleName: String, eventName: String) {
        self.moduleName = moduleName
        self.eventName = eventName
    }
}
