import Foundation

public enum GenericEventNodeError: Error {
    case unexpectedParams
    case unexpectedEventModule(value: UInt8)
    case unexpectedEventIndex(value: UInt32)
    case argumentsNotMatchingParams(arguments: [String], params: [JSON])
    case unexpectedDecodedModule
    case unexpectedDecodedEventIndex
}

public class GenericEventNode: Node {
    public var typeName: String { GenericType.event.name }
    public let runtimeMetadata: RuntimeMetadataProtocol

    public init(runtimeMetadata: RuntimeMetadataProtocol) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let input = value.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: value)
        }

        guard
            input.count == 3,
            let eventModule = input[0].unsignedIntValue,
            let eventIndex = input[1].unsignedIntValue,
            let params = input[2].arrayValue else {
            throw GenericEventNodeError.unexpectedParams
        }

        guard let event = runtimeMetadata.getEventForModuleIndex(
                UInt8(eventModule),
                eventIndex: UInt32(eventIndex)
        ) else {
            throw GenericEventNodeError.unexpectedEventIndex(value: UInt32(eventIndex))
        }

        let arguments = event.arguments

        guard arguments.count == params.count else {
            throw GenericEventNodeError.argumentsNotMatchingParams(arguments: arguments,
                                                                   params: params)
        }

        try encoder.appendU8(json: .stringValue(String(eventModule)))
        try encoder.appendU8(json: .stringValue(String(eventIndex)))

        for index in 0..<arguments.count {
            try encoder.append(json: params[index], type: arguments[index])
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let eventModuleString = (try decoder.readU8()).stringValue,
              let eventModule = UInt8(eventModuleString) else {
            throw GenericEventNodeError.unexpectedDecodedModule
        }

        guard let eventString = (try decoder.readU8()).stringValue,
              let eventIndex = UInt32(eventString) else {
            throw GenericEventNodeError.unexpectedDecodedEventIndex
        }

        guard let event = runtimeMetadata.getEventForModuleIndex(eventModule, eventIndex: eventIndex) else {
            throw GenericEventNodeError.unexpectedEventIndex(value: eventIndex)
        }

        let arguments = event.arguments

        let params: [JSON] = try arguments.map { try decoder.read(type: $0)}

        return .arrayValue([
            .unsignedIntValue(UInt64(eventModule)),
            .unsignedIntValue(UInt64(eventIndex)),
            .arrayValue(params)
        ])
    }
}
