import Foundation

public struct EraNode: Node {
    public var typeName: String { GenericType.era.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let values = value.arrayValue, !values.isEmpty else {
            throw DynamicScaleEncoderError.arrayExpected(json: value)
        }

        guard let type = values[0].unsignedIntValue else {
            throw DynamicScaleEncoderError.unsignedIntExpected(json: values[0])
        }

        switch type {
        case 0:
            try encoder.append(encodable: Era.immortal)
        case 1:
            guard values.count == 2,
                  let params = value[1]?.arrayValue,
                  params.count == 2,
                  let period = params[0].unsignedIntValue,
                  let phase = params[1].unsignedIntValue else {
                throw DynamicScaleEncoderError.unexpectedEnumJSON(json: value)
            }

            try encoder.append(encodable: Era.mortal(period: period, phase: phase))
        default:
            throw DynamicScaleEncoderError.unsignedIntExpected(json: values[0])
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let era: Era? = try decoder.read()

        switch era {
        case .immortal:
            return .arrayValue([.unsignedIntValue(0)])
        case .mortal(let period, let phase):
            let values: [JSON] = [
                .unsignedIntValue(1),
                .arrayValue([.unsignedIntValue(period), .unsignedIntValue(phase)])
            ]
            return .arrayValue(values)
        case .none:
            return .null
        }
    }
}
