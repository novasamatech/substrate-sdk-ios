import Foundation
import BigInt

public class DynamicScaleDecoder {
    private var decoder: ScaleDecoder
    public let registry: TypeRegistryCatalogProtocol
    public let version: UInt64

    private var modifiers: [ScaleCodingModifier] = []

    public init(data: Data, registry: TypeRegistryCatalogProtocol, version: UInt64) throws {
        decoder = try ScaleDecoder(data: data)
        self.registry = registry
        self.version = version
    }

    private func resolveOptionIfNeeded() throws -> Bool {
        if modifiers.last == .option {
            modifiers.removeLast()

            let mode = try decoder.readAndConfirm(count: 1)[0]

            switch mode {
            case 0:
                return true
            case 1:
                return false
            default:
                throw DynamicScaleDecoderError.unexpectedOption(byte: mode)
            }
        }

        return false
    }

    func decodeCompactOrFixedInt(length: Int) throws -> JSON {
        if modifiers.last == .compact {
            modifiers.removeLast()

            return try decodeCompact()
        } else {
            return try decodeFixedInt(length: length)
        }
    }

    private func decodeCompact() throws -> JSON {
        let compact = try BigUInt(scaleDecoder: decoder)
        return .stringValue(String(compact))
    }

    private func decodeFixedInt(length: Int) throws -> JSON {
        let data = try decoder.readAndConfirm(count: length)
        let value = BigUInt(Data(data.reversed()))
        return .stringValue(String(value))
    }
}

extension DynamicScaleDecoder: DynamicScaleDecoding {
    public var remained: Int { decoder.remained }

    public func read(type: String) throws -> JSON {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        return try node.accept(decoder: self)
    }

    public func readOption(type: String) throws -> JSON {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        modifiers.append(.option)

        return try node.accept(decoder: self)
    }

    public func readVector(type: String) throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        let length = try BigUInt(scaleDecoder: decoder)

        let jsons = try (0..<length).map { _ in try node.accept(decoder: self) }

        return .arrayValue(jsons)
    }

    public func readCompact(type: String) throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        modifiers.append(.compact)

        return try node.accept(decoder: self)
    }

    public func readFixedArray(type: String, length: UInt64) throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolverType(name: type)
        }

        let jsons = try (0..<length).map { _ in try node.accept(decoder: self) }

        return .arrayValue(jsons)
    }

    public func readBytes(length: Int) throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        let hex = try decoder.readAndConfirm(count: length).toHex(includePrefix: true)

        return .stringValue(hex)
    }

    public func readString() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        let string = try String(scaleDecoder: decoder)
        return .stringValue(string)
    }

    public func readU8() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        return try decodeCompactOrFixedInt(length: 1)
    }

    public func readU16() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        return try decodeCompactOrFixedInt(length: 2)
    }

    public func readU32() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        return try decodeCompactOrFixedInt(length: 4)
    }

    public func readU64() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        return try decodeCompactOrFixedInt(length: 8)
    }

    public func readU128() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        return try decodeCompactOrFixedInt(length: 16)
    }

    public func readU256() throws -> JSON {
        if try resolveOptionIfNeeded() {
            return .null
        }

        return try decodeCompactOrFixedInt(length: 32)
    }

    public func readBool() throws -> JSON {
        if modifiers.last == .option {
            let value = try ScaleBoolOption(scaleDecoder: decoder)

            switch value {
            case .none:
                return .null
            case .valueTrue:
                return .boolValue(true)
            case .valueFalse:
                return .boolValue(false)
            }

        } else {
            let value = try Bool(scaleDecoder: decoder)
            return .boolValue(value)
        }
    }

    public func read<T: ScaleCodable>() throws -> T? {
        let modifier: ScaleCodingModifier? = !modifiers.isEmpty ? modifiers.last : nil

        if modifier != nil {
            modifiers.removeLast()
        }

        if modifier == .option {
            return try ScaleOption<T>(scaleDecoder: decoder).value
        } else {
            return try T(scaleDecoder: decoder)
        }
    }
}
