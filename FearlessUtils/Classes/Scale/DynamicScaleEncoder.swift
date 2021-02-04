import Foundation
import BigInt

public enum DynamicScaleEncoderError: Error {
    case unresolverType(name: String)
    case arrayExpected(json: JSON)
    case unexpectedNull
    case hexExpected(json: JSON)
    case expectedStringForCompact(json: JSON)
    case expectedStringForInt(json: JSON)
    case expectedStringForBool(json: JSON)
    case missingOptionModifier
}

public final class DynamicScaleEncoder {
    enum Modifiers {
        case compact
        case option
    }

    private var encoder: ScaleEncoder = ScaleEncoder()

    private var modifiers: [Modifiers] = []

    public let registry: TypeRegistryCatalogProtocol
    public let version: UInt64

    public init(registry: TypeRegistryCatalogProtocol, version: UInt64) {
        self.registry = registry
        self.version = version
    }

    private func resolveOptionIfNeeded(for json: JSON) throws -> Bool {
        if modifiers.last == .option {
            modifiers.removeLast()

            if case .null = json {
                encoder.appendRaw(data: Data([0]))

                return true
            } else {
                encoder.appendRaw(data: Data([1]))

                return false
            }
        } else if case .null = json {
            throw DynamicScaleEncoderError.unexpectedNull
        }

        return false
    }

    private func encodeCompact(value: JSON) throws {
        guard let str = value.stringValue, let bigInt = BigUInt(str) else {
            throw DynamicScaleEncoderError.expectedStringForCompact(json: value)
        }

        try bigInt.encode(scaleEncoder: encoder)
    }

    private func encodeFixedInt(value: JSON, byteLength: Int) throws {
        guard let str = value.stringValue, let intValue = BigUInt(str) else {
            throw DynamicScaleEncoderError.expectedStringForInt(json: value)
        }

        var encodedData: [UInt8] = intValue.serialize().reversed()

        while encodedData.count < byteLength {
            encodedData.append(0)
        }

        encoder.appendRaw(data: Data(encodedData))
    }

    private func appendFixedUnsigned(json: JSON, byteLength: Int) throws {
        if try resolveOptionIfNeeded(for: json) {
            return
        }

        if modifiers.last == .compact {
            modifiers.removeLast()

           try encodeCompact(value: json)
        } else {
            try encodeFixedInt(value: json, byteLength: byteLength)
        }
    }
}

extension DynamicScaleEncoder: DynamicScaleEncoding {
    public func append(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleEncoderError.unresolverType(name: type)
        }

        try node.accept(encoder: self, value: json)
    }

    public func appendOption(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleEncoderError.unresolverType(name: type)
        }

        modifiers.append(.option)

        try node.accept(encoder: self, value: json)
    }

    public func appendVector(json: JSON, type: String) throws {
        if try resolveOptionIfNeeded(for: json) {
            return
        }

        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleEncoderError.unresolverType(name: type)
        }

        guard let items = json.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: json)
        }

        try BigUInt(items.count).encode(scaleEncoder: encoder)

        for item in items {
            try node.accept(encoder: self, value: item)
        }
    }

    public func appendCompact(json: JSON, type: String) throws {
        if try resolveOptionIfNeeded(for: json) {
            return
        }

        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleEncoderError.unresolverType(name: type)
        }

        modifiers.append(.compact)

        try node.accept(encoder: self, value: json)
    }

    public func appendFixedArray(json: JSON, type: String) throws {
        if try resolveOptionIfNeeded(for: json) {
            return
        }

        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleEncoderError.unresolverType(name: type)
        }

        guard let items = json.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: json)
        }

        for item in items {
            try node.accept(encoder: self, value: item)
        }
    }

    public func appendBytes(json: JSON) throws {
        if try resolveOptionIfNeeded(for: json) {
            return
        }

        guard let hex = json.stringValue, let data = try? Data(hexString: hex) else {
            throw DynamicScaleEncoderError.hexExpected(json: json)
        }

        encoder.appendRaw(data: data)
    }

    public func appendString(json: JSON) throws {
        if try resolveOptionIfNeeded(for: json) {
            return
        }

        guard let str = json.stringValue else {
            throw DynamicScaleEncoderError.hexExpected(json: json)
        }

        try str.encode(scaleEncoder: encoder)
    }

    public func appendU8(json: JSON) throws {
        try appendFixedUnsigned(json: json, byteLength: 1)
    }

    public func appendU16(json: JSON) throws {
        try appendFixedUnsigned(json: json, byteLength: 2)
    }

    public func appendU32(json: JSON) throws {
        try appendFixedUnsigned(json: json, byteLength: 4)
    }

    public func appendU64(json: JSON) throws {
        try appendFixedUnsigned(json: json, byteLength: 8)
    }

    public func appendU128(json: JSON) throws {
        try appendFixedUnsigned(json: json, byteLength: 16)
    }

    public func appendU256(json: JSON) throws {
        try appendFixedUnsigned(json: json, byteLength: 32)
    }

    public func appendBool(json: JSON) throws {
        guard let str = json.stringValue, let value = Bool(str) else {
            throw DynamicScaleEncoderError.expectedStringForBool(json: json)
        }

        if modifiers.last == .option {
            modifiers.removeLast()

            try ScaleBoolOption(value: value).encode(scaleEncoder: encoder)
        } else {
            try value.encode(scaleEncoder: encoder)
        }
    }

    public func appendNull() throws {
        guard modifiers.last == .option else {
            throw DynamicScaleEncoderError.missingOptionModifier
        }

        modifiers.removeLast()

        encoder.appendRaw(data: Data([0]))
    }

    public func encode() throws -> Data {
        encoder.encode()
    }
}
