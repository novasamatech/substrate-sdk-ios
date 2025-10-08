import Foundation

public protocol SigningWrapperFactoryProtocol {
    func createSigningWrapper(for account: AccountProtocol) -> SigningWrapperProtocol
}
