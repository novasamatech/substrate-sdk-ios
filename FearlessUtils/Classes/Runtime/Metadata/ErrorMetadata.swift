import Foundation

public struct ErrorMetadata {
    public let name: String
    public let documentation: [String]

    public init(name: String, documentation: [String]) {
        self.name = name
        self.documentation = documentation
    }
}

extension ErrorMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
