import Foundation
import NovaCrypto

enum DefaultSigningWrapperError: Error {
    case missingSignerAccount
}

public final class DefaultSigningWrapper {
    let secretProvider: SigningSecretProviding
    
    public init(secretProvider: SigningSecretProviding) {
        self.secretProvider = secretProvider
    }
}

private extension DefaultSigningWrapper {
    func signWithSubstrateCrypto(
        _ data: Data,
        secretKey: Data,
        account: AccountProtocol
    ) throws -> IRSignatureProtocol {
        switch account.signatureType {
        case .sr25519:
            return try signSr25519(data, secretKeyData: secretKey, publicKeyData: account.publicKey)
        case .ed25519:
            return try signEd25519(data, secretKey: secretKey)
        case .ecdsa:
            return try signEcdsa(data, secretKey: secretKey)
        }
    }
}

extension DefaultSigningWrapper: SigningWrapperProtocol {
    public func sign(_ originalData: Data, context: SigningContext) throws -> IRSignatureProtocol {
        let secretKey = try secretProvider.fetchSignerSecret(for: context.signerProvider)
        
        guard let account = context.signerProvider.account else {
            throw DefaultSigningWrapperError.missingSignerAccount
        }
        
        switch account.signatureFormat {
        case .substrate:
            return try signWithSubstrateCrypto(originalData, secretKey: secretKey, account: account)
        case .ethereum:
            return try signEthereum(originalData, secretKey: secretKey)
        }
    }
}
