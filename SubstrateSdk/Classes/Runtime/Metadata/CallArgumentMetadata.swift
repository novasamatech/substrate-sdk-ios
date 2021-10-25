import Foundation

public struct CallArgumentMetadata {
    public let name: String
    public let type: String

    public init(name: String, type: String) {
        self.name = name
        self.type = type
    }
}

extension CallArgumentMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        type = try String(scaleDecoder: scaleDecoder)
    }
}
