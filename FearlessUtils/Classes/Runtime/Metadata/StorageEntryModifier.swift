import Foundation

public enum StorageEntryModifier: UInt8 {
    case optional
    case defaultModifier
}

extension StorageEntryModifier: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try rawValue.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let rawValue = try UInt8(scaleDecoder: scaleDecoder)

        guard let value = StorageEntryModifier(rawValue: rawValue)  else {
            throw ScaleCodingError.unexpectedDecodedValue
        }

        self = value
    }
}
