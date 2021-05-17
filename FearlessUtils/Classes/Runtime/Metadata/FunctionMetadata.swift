import Foundation

public struct FunctionMetadata {
    public let name: String
    public let arguments: [FunctionArgumentMetadata]
    public let documentation: [String]

    public init(name: String, arguments: [FunctionArgumentMetadata], documentation: [String]) {
        self.name = name
        self.arguments = arguments
        self.documentation = documentation
    }
}

extension FunctionMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try arguments.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        arguments = try [FunctionArgumentMetadata](scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}
