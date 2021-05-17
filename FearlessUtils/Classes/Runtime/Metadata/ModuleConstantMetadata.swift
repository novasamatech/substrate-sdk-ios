import Foundation

public struct ModuleConstantMetadata {
    public let name: String
    public let type: String
    public let value: Data
    public let documentation: [String]

    public init(name: String, type: String, value: Data, documentation: [String]) {
        self.name = name
        self.type = type
        self.value = value
        self.documentation = documentation
    }
}

extension ModuleConstantMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
        try value.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        type = try String(scaleDecoder: scaleDecoder)
        value = try Data(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
