import Foundation
import NovaCrypto

public final class DummySigner {
    let defaultSigner: DefaultSigningWrapper
    
    public init(signatureType: CryptoType, seed: Data = Data(repeating: 1, count: 32)) throws {
        switch signatureType {
        case .sr25519:
            let keypair = try SNKeyFactory().createKeypair(fromSeed: seed)
            defaultSigner = DefaultSigningWrapper(secretProvider: keypair.privateKey().rawData())
        case .ed25519:
            defaultSigner = DefaultSigningWrapper(secretProvider: seed)
        case .ecdsa:
            defaultSigner = DefaultSigningWrapper(secretProvider: seed)
        }
    }
}

extension DummySigner: SigningWrapperProtocol {
    public func sign(
        _ originalData: Data,
        context: SigningContext
    ) throws -> IRSignatureProtocol {
        try defaultSigner.sign(originalData, context: context)
    }
}
