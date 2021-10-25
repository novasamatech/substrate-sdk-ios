import Foundation

public struct CallMetadata {
    public let name: String
    public let arguments: [CallArgumentMetadata]
    public let documentation: [String]

    public init(name: String, arguments: [CallArgumentMetadata], documentation: [String]) {
        self.name = name
        self.arguments = arguments
        self.documentation = documentation
    }
}

extension CallMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try arguments.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        arguments = try [CallArgumentMetadata](scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
