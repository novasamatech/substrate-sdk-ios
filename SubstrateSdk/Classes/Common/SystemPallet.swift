import Foundation

public enum SystemPallet {
    static let name = "System"
}

public extension SystemPallet {
    static var extrinsicSuccessEventPath: EventCodingPath {
        .init(moduleName: name, eventName: "ExtrinsicSuccess")
    }

    static var extrinsicFailedEventPath: EventCodingPath {
        .init(moduleName: name, eventName: "ExtrinsicFailed")
    }
}

public extension SystemPallet {
    static var eventsPath: StorageCodingPath {
        StorageCodingPath(moduleName: name, itemName: "Events")
    }
}
