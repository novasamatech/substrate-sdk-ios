import Foundation

public protocol AccountProtocol: SignerProviding {
    var accountId: AccountId { get }
    var publicKey: Data { get }
    var signatureFormat: ExtrinsicSignatureFormat { get }
    var signaturePayloadFormat: ExtrinsicSignaturePayloadFormat { get }
    var signatureType: CryptoType { get }
    
    func toAddress() throws -> AccountAddress
}

public extension AccountProtocol {
    var account: AccountProtocol? {
        self
    }
}
