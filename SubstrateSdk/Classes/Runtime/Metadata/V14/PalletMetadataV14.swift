import Foundation

public struct PalletMetadataV14 {
    public let name: String
    public let storage: StorageMetadataV14?
    public let calls: CallMetadataV14?
    public let events: EventMetadataV14?
    public let constants: [ConstantMetadataV14]
    public let errors: ErrorMetadataV14?
    public let index: UInt8

    public init(
        name: String,
        storage: StorageMetadataV14?,
        calls: CallMetadataV14?,
        events: EventMetadataV14?,
        constants: [ConstantMetadataV14],
        errors: ErrorMetadataV14?,
        index: UInt8
    ) {
        self.name = name
        self.storage = storage
        self.calls = calls
        self.events = events
        self.constants = constants
        self.errors = errors
        self.index = index
    }
}

extension PalletMetadataV14: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: storage).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: calls).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: events).encode(scaleEncoder: scaleEncoder)
        try constants.encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: errors).encode(scaleEncoder: scaleEncoder)
        try index.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        storage = try ScaleOption(scaleDecoder: scaleDecoder).value
        calls = try ScaleOption(scaleDecoder: scaleDecoder).value
        events = try ScaleOption(scaleDecoder: scaleDecoder).value
        constants = try [ConstantMetadataV14](scaleDecoder: scaleDecoder)
        errors = try ScaleOption(scaleDecoder: scaleDecoder).value
        index = try UInt8(scaleDecoder: scaleDecoder)
    }
}
