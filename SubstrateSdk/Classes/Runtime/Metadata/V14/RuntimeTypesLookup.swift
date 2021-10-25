import Foundation

public struct RuntimeTypesLookup {
    public let types: [PortableType]

    public init(types: [PortableType]) {
        self.types = types
    }
}

extension RuntimeTypesLookup: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try types.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        types = try [PortableType](scaleDecoder: scaleDecoder)
    }
}
