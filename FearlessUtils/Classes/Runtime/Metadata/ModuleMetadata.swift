import Foundation

public struct ModuleMetadata {
    public let name: String
    public let storage: StorageMetadata?
    public let calls: [FunctionMetadata]?
    public let events: [EventMetadata]?
    public let constants: [ModuleConstantMetadata]
    public let errors: [ErrorMetadata]
    public let index: UInt8

    public init(name: String,
                storage: StorageMetadata?,
                calls: [FunctionMetadata]?,
                events: [EventMetadata]?,
                constants: [ModuleConstantMetadata],
                errors: [ErrorMetadata],
                index: UInt8) {
        self.name = name
        self.storage = storage
        self.calls = calls
        self.events = events
        self.constants = constants
        self.errors = errors
        self.index = index
    }
}

extension ModuleMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: storage).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: calls).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: events).encode(scaleEncoder: scaleEncoder)
        try constants.encode(scaleEncoder: scaleEncoder)
        try errors.encode(scaleEncoder: scaleEncoder)
        try index.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        storage = try ScaleOption(scaleDecoder: scaleDecoder).value
        calls = try ScaleOption(scaleDecoder: scaleDecoder).value
        events = try ScaleOption(scaleDecoder: scaleDecoder).value
        constants = try [ModuleConstantMetadata](scaleDecoder: scaleDecoder)
        errors = try [ErrorMetadata](scaleDecoder: scaleDecoder)
        index = try UInt8(scaleDecoder: scaleDecoder)
    }
}
