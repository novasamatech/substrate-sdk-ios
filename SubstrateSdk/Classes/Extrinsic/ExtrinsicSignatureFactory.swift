import Foundation

public protocol ExtrinsicSignatureFactoryProtocol {
    func createSignature(
        from payload: Data,
        context: RuntimeJsonContext?
    ) throws -> JSON
}

public final class MultiSignatureExtrinsicFactory: ExtrinsicSignatureFactoryProtocol {
    public let signer: (Data) throws -> Data
    public let cryptoType: CryptoType

    public init(signer: @escaping (Data) throws -> Data, cryptoType: CryptoType) {
        self.signer = signer
        self.cryptoType = cryptoType
    }

    public func createSignature(
        from payload: Data,
        context: RuntimeJsonContext?
    ) throws -> JSON {
        let rawSignature = try signer(payload)

        let signature: MultiSignature

        switch cryptoType {
        case .sr25519:
            signature = .sr25519(data: rawSignature)
        case .ed25519:
            signature = .ed25519(data: rawSignature)
        case .ecdsa:
            signature = .ecdsa(data: rawSignature)
        }

        return try signature.toScaleCompatibleJSON(with: context?.toRawContext())
    }
}

public class ClosureSignatureExtrinsicFactory: ExtrinsicSignatureFactoryProtocol {
    public let signer: (Data) throws -> JSON

    init(signer: @escaping (Data) throws -> JSON) {
        self.signer = signer
    }

    public func createSignature(from payload: Data, context _: RuntimeJsonContext?) throws -> JSON {
        try signer(payload)
    }
}
