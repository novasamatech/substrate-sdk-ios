import Foundation

public struct GenericMultiAddressNode: Node {
    public static let typeMapping = [
        ["Id", "AccountId"],
        ["Index", "Compact<AccountIndex>"],
        ["Raw", "Bytes"],
        ["Address32", "H256"],
        ["Address20", "H160"]
    ]

    public var typeName: String { "GenericMultiAddress" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard
            let enumValue = value.arrayValue,
            enumValue.count == 2,
            let caseValue = enumValue.first?.unsignedIntValue,
            let assocValue = enumValue.last else {
            throw DynamicScaleEncoderError.unexpectedEnumJSON(json: value)
        }

        guard caseValue < Self.typeMapping.count else {
            throw DynamicScaleEncoderError.unexpectedEnumCase(value: caseValue, count: Self.typeMapping.count)
        }

        try encoder.appendU8(json: .stringValue(String(caseValue)))
        try encoder.append(json: assocValue, type: Self.typeMapping[Int(caseValue)][1])
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let caseValueStr = try decoder.readU8().stringValue,
              let caseValue = Int(caseValueStr) else {
            throw DynamicScaleDecoderError.unexpectedEnumCase
        }

        guard caseValue < Self.typeMapping.count else {
            throw DynamicScaleDecoderError.invalidEnumCase(value: caseValue, count: Self.typeMapping.count)
        }

        let json = try decoder.read(type: Self.typeMapping[caseValue][1])

        return .arrayValue([.unsignedIntValue(UInt64(caseValue)), json])
    }
}
