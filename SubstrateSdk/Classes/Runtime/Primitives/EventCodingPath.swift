import Foundation
import SubstrateSdk

public struct EventCodingPath: Equatable, Hashable {
    let moduleName: String
    let eventName: String

    public init(moduleName: String, eventName: String) {
        self.moduleName = moduleName
        self.eventName = eventName
    }
}
