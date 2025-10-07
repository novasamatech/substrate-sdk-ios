import Foundation

public protocol AccountProtocol {
    var accountId: AccountId { get }
    var signatureFormat: ExtrinsicSignatureFormat { get }
    var signaturePayloadFormat: ExtrinsicSignaturePayloadFormat { get }
    var signatureType: SubstrateSdk.CryptoType { get }
    
    func toAddress() throws -> AccountAddress
}
