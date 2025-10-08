import Foundation

public final class DefaultSigningWrapperFactory {
    let secretProvider: SigningSecretProviding
    
    public init(secretProvider: SigningSecretProviding) {
        self.secretProvider = secretProvider
    }
}

extension DefaultSigningWrapper: SigningWrapperFactoryProtocol {
    public func createSigningWrapper(for account: AccountProtocol) -> SigningWrapperProtocol {
        DefaultSigningWrapper(secretProvider: secretProvider)
    }
}
