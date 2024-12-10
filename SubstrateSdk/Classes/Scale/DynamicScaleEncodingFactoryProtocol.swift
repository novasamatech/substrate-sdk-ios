import Foundation

public protocol DynamicScaleEncodingFactoryProtocol {
    func createEncoder() -> DynamicScaleEncoding
}

public final class WrappedDynamicScaleEncoderFactory: DynamicScaleEncodingFactoryProtocol {
    public let encoder: DynamicScaleEncoding
    
    public init(encoder: DynamicScaleEncoding) {
        self.encoder = encoder
    }
    
    public func createEncoder() -> DynamicScaleEncoding {
        encoder.newEncoder()
    }
}
