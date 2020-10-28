import Foundation

public protocol SubstrateQREncodable {
    func encode(receiverInfo: ReceiveInfo) throws -> Data {
}

public protocol SubstrateQRDecodable {
    
}
