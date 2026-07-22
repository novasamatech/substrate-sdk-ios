import Foundation

public struct PalletMetadataV16 {
    public let name: String
    public let storageV16: StorageMetadataV16?
    public let callsV16: CallMetadataV16?
    public let eventsV16: EventMetadataV16?
    public let constantsV16: [ConstantMetadataV16]
    public let errorsV16: ErrorMetadataV16?
    public let associatedTypes: [PalletAssociatedTypeMetadataV16]
    public let viewFunctions: [PalletViewFunctionMetadataV16]
    public let index: UInt8
    public let docs: [String]
    public let deprecationInfo: ItemDeprecationInfoV16

    public init(
        name: String,
        storageV16: StorageMetadataV16?,
        callsV16: CallMetadataV16?,
        eventsV16: EventMetadataV16?,
        constantsV16: [ConstantMetadataV16],
        errorsV16: ErrorMetadataV16?,
        associatedTypes: [PalletAssociatedTypeMetadataV16],
        viewFunctions: [PalletViewFunctionMetadataV16],
        index: UInt8,
        docs: [String],
        deprecationInfo: ItemDeprecationInfoV16
    ) {
        self.name = name
        self.storageV16 = storageV16
        self.callsV16 = callsV16
        self.eventsV16 = eventsV16
        self.constantsV16 = constantsV16
        self.errorsV16 = errorsV16
        self.associatedTypes = associatedTypes
        self.viewFunctions = viewFunctions
        self.index = index
        self.docs = docs
        self.deprecationInfo = deprecationInfo
    }
}

extension PalletMetadataV16: PostV14PalletMetadataProtocol {
    public var storage: StorageMetadataV14? {
        storageV16.map { storage in
            StorageMetadataV14(
                prefix: storage.prefix,
                entries: storage.entries.map {
                    StorageEntryMetadataV14(
                        name: $0.name,
                        modifier: $0.modifier,
                        type: $0.type,
                        defaultValue: $0.defaultValue,
                        documentation: $0.documentation
                    )
                }
            )
        }
    }

    public var calls: CallMetadataV14? {
        callsV16.map { CallMetadataV14(type: $0.type) }
    }

    public var events: EventMetadataV14? {
        eventsV16.map { EventMetadataV14(type: $0.type) }
    }

    public var constants: [ConstantMetadataV14] {
        constantsV16.map {
            ConstantMetadataV14(
                name: $0.name,
                type: $0.type,
                value: $0.value,
                documentation: $0.documentation
            )
        }
    }

    public var errors: ErrorMetadataV14? {
        errorsV16.map { ErrorMetadataV14(type: $0.type) }
    }
}

extension PalletMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: storageV16).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: callsV16).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: eventsV16).encode(scaleEncoder: scaleEncoder)
        try constantsV16.encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: errorsV16).encode(scaleEncoder: scaleEncoder)
        try associatedTypes.encode(scaleEncoder: scaleEncoder)
        try viewFunctions.encode(scaleEncoder: scaleEncoder)
        try index.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
        try deprecationInfo.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        storageV16 = try ScaleOption(scaleDecoder: scaleDecoder).value
        callsV16 = try ScaleOption(scaleDecoder: scaleDecoder).value
        eventsV16 = try ScaleOption(scaleDecoder: scaleDecoder).value
        constantsV16 = try [ConstantMetadataV16](scaleDecoder: scaleDecoder)
        errorsV16 = try ScaleOption(scaleDecoder: scaleDecoder).value
        associatedTypes = try [PalletAssociatedTypeMetadataV16](scaleDecoder: scaleDecoder)
        viewFunctions = try [PalletViewFunctionMetadataV16](scaleDecoder: scaleDecoder)
        index = try UInt8(scaleDecoder: scaleDecoder)
        docs = try [String](scaleDecoder: scaleDecoder)
        deprecationInfo = try ItemDeprecationInfoV16(scaleDecoder: scaleDecoder)
    }
}
