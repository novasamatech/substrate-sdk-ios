import Foundation

public struct EnumValuesNode: Node {
    public let typeName: String
    public let values: [String]

    public init(typeName: String, values: [String]) {
        self.typeName = typeName
        self.values = values
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let caseValue = value.unsignedIntValue else {
            throw DynamicScaleEncoderError.unexpectedEnumJSON(json: value)
        }

        guard caseValue < values.count else {
            throw DynamicScaleEncoderError.unexpectedEnumCase(value: caseValue, count: values.count)
        }

        try encoder.appendU8(json: .stringValue(String(caseValue)))
    }
}
