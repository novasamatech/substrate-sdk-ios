import Foundation
import BigInt

public final class DynamicScaleEncoder {
    private var encoder = ScaleEncoder()

    private var modifiers: [ScaleCodingModifier] = []

    public let registry: TypeRegistryCatalogProtocol
    public let version: UInt64

    public init(registry: TypeRegistryCatalogProtocol, version: UInt64) {
        self.registry = registry
        self.version = version
    }

    private func handleCommonOption(isNull: Bool) {
        if isNull {
            encoder.appendRaw(data: Data([0]))
        } else {
            encoder.appendRaw(data: Data([1]))
        }
    }

    private func handleCommonOption(for json: JSON) {
        if case .null = json {
            handleCommonOption(isNull: true)
        } else {
            handleCommonOption(isNull: false)
        }
    }

    private func handleBoolOption(for value: Bool?) throws {
        try ScaleBoolOption(value: value).encode(scaleEncoder: encoder)
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

    private func encodeFixedSignedInt(value: JSON, byteLength: Int) throws {
        guard let str = value.stringValue, let intValue = BigInt(str) else {
            throw DynamicScaleEncoderError.expectedStringForInt(json: value)
        }

        let magnitude: BigUInt

        switch intValue.sign {
        case .plus:
            magnitude = intValue.magnitude
        case .minus:
            let bitLength = 8 * byteLength
            let invertingMask = (BigUInt(1) << bitLength) - 1
            magnitude = (intValue.magnitude ^ invertingMask) + 1
        }

        var encodedData: [UInt8] = magnitude.serialize().reversed()

        while encodedData.count < byteLength {
            encodedData.append(0)
        }

        encoder.appendRaw(data: Data(encodedData))
    }

    private func appendFixedUnsigned(json: JSON, byteLength: Int) throws {
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
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        try node.accept(encoder: self, value: json)
    }

    public func appendOption(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        if node is BoolNode {
            try handleBoolOption(for: json.boolValue)
        } else {
            handleCommonOption(for: json)

            if !json.isNull {
                try node.accept(encoder: self, value: json)
            }
        }
    }

    public func appendVector(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
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
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        modifiers.append(.compact)

        try node.accept(encoder: self, value: json)
    }

    public func appendFixedArray(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        guard let items = json.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: json)
        }

        for item in items {
            try node.accept(encoder: self, value: item)
        }
    }

    public func appendBytes(json: JSON) throws {
        guard let hex = json.stringValue, let data = try? Data(hexString: hex) else {
            throw DynamicScaleEncoderError.hexExpected(json: json)
        }

        encoder.appendRaw(data: data)
    }

    public func appendRawData(_ data: Data) throws {
        encoder.appendRaw(data: data)
    }

    public func appendCommonOption(isNull: Bool) throws {
        handleCommonOption(isNull: isNull)
    }

    public func appendString(json: JSON) throws {
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

    public func appendI8(json: JSON) throws {
        try encodeFixedSignedInt(value: json, byteLength: 1)
    }

    public func appendI16(json: JSON) throws {
        try encodeFixedSignedInt(value: json, byteLength: 2)
    }

    public func appendI32(json: JSON) throws {
        try encodeFixedSignedInt(value: json, byteLength: 4)
    }

    public func appendI64(json: JSON) throws {
        try encodeFixedSignedInt(value: json, byteLength: 8)
    }

    public func appendI128(json: JSON) throws {
        try encodeFixedSignedInt(value: json, byteLength: 16)
    }

    public func appendI256(json: JSON) throws {
        try encodeFixedSignedInt(value: json, byteLength: 32)
    }

    public func appendBool(json: JSON) throws {
        guard let value = json.boolValue else {
            throw DynamicScaleEncoderError.expectedStringForBool(json: json)
        }

        try value.encode(scaleEncoder: encoder)
    }

    public func append<T: ScaleCodable>(encodable: T) throws {
        try encodable.encode(scaleEncoder: encoder)
    }

    public func newEncoder() -> DynamicScaleEncoding {
        DynamicScaleEncoder(registry: registry, version: version)
    }

    public func canEncodeOptional(for type: String) -> Bool {
        guard let node = registry.node(for: type, version: version) else {
            return false
        }

        if let proxyNode = node as? ProxyNode {
            return canEncodeOptional(for: proxyNode.typeName)
        } else if let aliasNode = node as? AliasNode {
            return canEncodeOptional(for: aliasNode.underlyingTypeName)
        } else {
            return node is OptionNode
        }
    }

    public func encode() throws -> Data {
        encoder.encode()
    }
}
