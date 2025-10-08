import Foundation

public protocol SigningSecretProviding {
    func fetchSignerSecret(for signer: SignerProviding) throws -> Data
}

extension Data: SigningSecretProviding {
    public func fetchSignerSecret(for signer: SignerProviding) throws -> Data {
        self
    }
}
