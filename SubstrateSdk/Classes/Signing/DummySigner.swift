import Foundation
import NovaCrypto

public final class DummySigner {
    let defaultSigner: DefaultSigningWrapper
    
    public init(seed: Data = Data(repeating: 1, count: 32)) {
        defaultSigner = DefaultSigningWrapper(secretProvider: seed)
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
