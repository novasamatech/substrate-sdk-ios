import Foundation
import BigInt

public typealias SiLookupId = UInt32

public struct PortableType {
    public let identifier: SiLookupId
    public let type: RuntimeType

    init(identifier: SiLookupId, type: RuntimeType) {
        self.identifier = identifier
        self.type = type
    }
}

extension PortableType: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(identifier).encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        identifier = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        type = try RuntimeType(scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeType {
    public let path: [String]
    public let parameters: [RuntimeTypeParameter]
    public let typeDefinition: RuntimeTypeDefinition
    public let docs: [String]

    public init(
        path: [String],
        parameters: [RuntimeTypeParameter],
        typeDefinition: RuntimeTypeDefinition,
        docs: [String]
    ) {
        self.path = path
        self.parameters = parameters
        self.typeDefinition = typeDefinition
        self.docs = docs
    }
}

extension RuntimeType {
    var pathBasedName: String? {
        !path.isEmpty ? path.joined(separator: ".") : nil
    }
}

extension RuntimeType: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try path.encode(scaleEncoder: scaleEncoder)
        try parameters.encode(scaleEncoder: scaleEncoder)
        try typeDefinition.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        path = try [String](scaleDecoder: scaleDecoder)
        parameters = try [RuntimeTypeParameter](scaleDecoder: scaleDecoder)
        typeDefinition = try RuntimeTypeDefinition(scaleDecoder: scaleDecoder)
        docs = try [String](scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeTypeParameter {
    public let name: String
    public let type: SiLookupId?

    public init(name: String, type: SiLookupId?) {
        self.name = name
        self.type = type
    }
}

extension RuntimeTypeParameter: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)

        let compactId = type.map { BigUInt($0) }
        try ScaleOption(value: compactId).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)

        let compactId: BigUInt? = try ScaleOption(scaleDecoder: scaleDecoder).value
        type = compactId.map { SiLookupId($0) }
    }
}

public enum RuntimeTypeDefinition {
    case composite(_ value: RuntimeTypeComposite)
    case variant(_ value: RuntimeTypeVariant)
    case sequence(_ value: RuntimeTypeSequence)
    case array(_ value: RuntimeTypeArray)
    case tuple(_ value: RuntimeTypeTuple)
    case primitive(_ value: RuntimeTypePrimitive)
    case compact(_ value: RuntimeTypeCompact)
    case bitsequence(_ value: RuntimeTypeBitSequence)
}

extension RuntimeTypeDefinition: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case .composite(let value):
            try UInt8(0).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .variant(let value):
            try UInt8(1).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .sequence(let value):
            try UInt8(2).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .array(let value):
            try UInt8(3).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .tuple(let value):
            try UInt8(4).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .primitive(let value):
            try UInt8(5).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .compact(let value):
            try UInt8(6).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        case .bitsequence(let value):
            try UInt8(7).encode(scaleEncoder: scaleEncoder)
            try value.encode(scaleEncoder: scaleEncoder)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        switch index {
        case 0:
            let value = try RuntimeTypeComposite(scaleDecoder: scaleDecoder)
            self = .composite(value)
        case 1:
            let value = try RuntimeTypeVariant(scaleDecoder: scaleDecoder)
            self = .variant(value)
        case 2:
            let value = try RuntimeTypeSequence(scaleDecoder: scaleDecoder)
            self = .sequence(value)
        case 3:
            let value = try RuntimeTypeArray(scaleDecoder: scaleDecoder)
            self = .array(value)
        case 4:
            let value = try RuntimeTypeTuple(scaleDecoder: scaleDecoder)
            self = .tuple(value)
        case 5:
            let value = try RuntimeTypePrimitive(scaleDecoder: scaleDecoder)
            self = .primitive(value)
        case 6:
            let value = try RuntimeTypeCompact(scaleDecoder: scaleDecoder)
            self = .compact(value)
        case 7:
            let value = try RuntimeTypeBitSequence(scaleDecoder: scaleDecoder)
            self = .bitsequence(value)
        default:
            throw ScaleCodingError.unexpectedDecodedValue
        }
    }
}

public struct RuntimeTypeField {
    public let name: String?
    public let type: SiLookupId
    public let typeName: String?
    public let docs: [String]

    public init(
        name: String?,
        type: SiLookupId,
        typeName: String?,
        docs: [String]
    ) {
        self.name = name
        self.type = type
        self.typeName = typeName
        self.docs = docs
    }
}

extension RuntimeTypeField: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try ScaleOption(value: name).encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: typeName).encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try ScaleOption(scaleDecoder: scaleDecoder).value
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        typeName = try ScaleOption(scaleDecoder: scaleDecoder).value
        docs = try [String](scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeTypeComposite {
    public let fields: [RuntimeTypeField]

    public init(fields: [RuntimeTypeField]) {
        self.fields = fields
    }
}

extension RuntimeTypeComposite: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try fields.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        fields = try [RuntimeTypeField](scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeTypeVariantItem {
    public let name: String
    public let fields: [RuntimeTypeField]
    public let index: UInt8
    public let docs: [String]

    public init(
        name: String,
        fields: [RuntimeTypeField],
        index: UInt8,
        docs: [String]
    ) {
        self.name = name
        self.fields = fields
        self.index = index
        self.docs = docs
    }
}

extension RuntimeTypeVariantItem: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try fields.encode(scaleEncoder: scaleEncoder)
        try index.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        fields = try [RuntimeTypeField](scaleDecoder: scaleDecoder)
        index = try UInt8(scaleDecoder: scaleDecoder)
        docs = try [String](scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeTypeVariant {
    public let variants: [RuntimeTypeVariantItem]

    public init(variants: [RuntimeTypeVariantItem]) {
        self.variants = variants
    }
}

extension RuntimeTypeVariant: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try variants.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        variants = try [RuntimeTypeVariantItem](scaleDecoder: scaleDecoder)
    }
}

public struct RuntimeTypeSequence {
    public let type: SiLookupId

    public init(type: SiLookupId) {
        self.type = type
    }
}

extension RuntimeTypeSequence: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}

public struct RuntimeTypeArray {
    public let length: UInt32
    public let type: SiLookupId

    public init(length: UInt32, type: SiLookupId) {
        self.length = length
        self.type = type
    }
}

extension RuntimeTypeArray: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try length.encode(scaleEncoder: scaleEncoder)
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        length = try UInt32(scaleDecoder: scaleDecoder)
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}

public struct RuntimeTypeTuple {
    public let components: [SiLookupId]

    public init(components: [SiLookupId]) {
        self.components = components
    }
}

extension RuntimeTypeTuple: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try components.map({ BigUInt($0) }).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let compactIds = try [BigUInt](scaleDecoder: scaleDecoder)
        components = compactIds.map { UInt32($0) }
    }
}

public enum RuntimeTypePrimitive: UInt8 {
    case bool
    case char
    case str
    case u8
    case u16
    case u32
    case u64
    case u128
    case u256
    case i8
    case i16
    case i32
    case i64
    case i128
    case i256
}

extension RuntimeTypePrimitive: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try rawValue.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)

        guard let value = RuntimeTypePrimitive(rawValue: index) else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        self = value
    }
}

public struct RuntimeTypeCompact {
    public let type: SiLookupId

    public init(type: SiLookupId) {
        self.type = type
    }
}

extension RuntimeTypeCompact: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(type).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        type = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}

public struct RuntimeTypeBitSequence {
    public let bitStoreType: SiLookupId
    public let bitOrderType: SiLookupId

    init(bitStoreType: SiLookupId, bitOrderType: SiLookupId) {
        self.bitStoreType = bitStoreType
        self.bitOrderType = bitOrderType
    }
}

extension RuntimeTypeBitSequence: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try BigUInt(bitStoreType).encode(scaleEncoder: scaleEncoder)
        try BigUInt(bitOrderType).encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        bitStoreType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
        bitOrderType = try SiLookupId(BigUInt(scaleDecoder: scaleDecoder))
    }
}
