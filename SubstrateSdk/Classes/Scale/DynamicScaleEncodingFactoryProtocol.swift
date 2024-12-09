import Foundation

public protocol DynamicScaleEncodingFactoryProtocol {
    func createEncoder() throws -> DynamicScaleEncoding
}
