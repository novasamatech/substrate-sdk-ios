import Foundation

public struct EventMetadata {
    public let name: String
    public let arguments: [String]
    public let documentation: [String]

    public init(name: String, arguments: [String], documentation: [String]) {
        self.name = name
        self.arguments = arguments
        self.documentation = documentation
    }
}

extension EventMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try arguments.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        arguments = try [String](scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
