import Foundation

public struct EventRecordNode: Node {
    public var typeName: String { "EventRecord" }
    public let runtimeMetadata: RuntimeMetadata

    public init(runtimeMetadata: RuntimeMetadata) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 3 else {
            throw DynamicScaleEncoderError.arrayExpected(json: value)
        }

        try encoder.append(json: params[0], type: "Phase")
        try encoder.append(json: params[1], type: "GenericEvent")
        try encoder.appendVector(json: params[2], type: "H256")
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let phase = try decoder.read(type: "Phase")
        let event = try decoder.read(type: "GenericEvent")
        let topics = try decoder.readVector(type: "H256")

        return .arrayValue([phase, event, topics])
    }
}
