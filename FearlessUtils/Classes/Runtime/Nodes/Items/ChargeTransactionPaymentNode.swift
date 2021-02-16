import Foundation

public struct ChargeTransactionPaymentNode: Node {
    public var typeName: String { "ChargeTransactionPayment" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 1 else {
            throw DynamicScaleCoderError.invalidParams
        }

        try encoder.appendCompact(json: params[0], type: KnownType.balance.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let tip = try decoder.readCompact(type: KnownType.balance.name)

        return .arrayValue([tip])
    }
}
