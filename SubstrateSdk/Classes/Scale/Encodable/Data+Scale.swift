import Foundation

extension Data: ScaleCodable {
    public init(scaleDecoder: ScaleDecoding) throws {
        let byteArray = try [UInt8](scaleDecoder: scaleDecoder)
        self = Data(byteArray)
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        let byteArray: [UInt8] = map { $0 }
        try byteArray.encode(scaleEncoder: scaleEncoder)
    }
}

public extension Data {
    func toScaleByteArray() -> [StringScaleMapper<UInt8>] {
        map { StringScaleMapper(value: $0) }
    }

    init(scaleByteArray: [StringScaleMapper<UInt8>]) {
        self.init(scaleByteArray.map { $0.value })
    }
}
