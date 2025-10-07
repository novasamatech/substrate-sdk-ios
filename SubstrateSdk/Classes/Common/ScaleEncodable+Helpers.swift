import Foundation

public extension ScaleEncodable {
    func scaleEncoded() throws -> Data {
        let scaleEncoder = ScaleEncoder()
        try encode(scaleEncoder: scaleEncoder)
        return scaleEncoder.encode()
    }
}
