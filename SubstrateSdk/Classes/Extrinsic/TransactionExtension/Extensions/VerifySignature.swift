import Foundation

public extension TransactionExtension {
    final class VerifySignature {
        public let usability: VerifySignature.Usability
        public let signaturePayloadFactory: ExtrinsicSignaturePayloadFactoryProtocol
        
        public init(
            extrinsicVersion: Extrinsic.Version,
            usability: Usability
        ) {
            self.usability = usability
            signaturePayloadFactory = ExtrinsicSignaturePayloadFactory(extrinsicVersion: extrinsicVersion)
        }
    }
}

public extension TransactionExtension.VerifySignature {
    struct SignedModel: Codable {
        let signature: JSON
        let account: JSON
    }
    
    enum Mode: Codable {
        case disabled
        case signed(SignedModel)
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            
            switch self {
            case .disabled:
                try container.encode("Disabled")
            case let .signed(model):
                try container.encode("Signed")
                try container.encode(model)
            }
        }
        
        enum CodingKeys: CodingKey {
            case disabled
            case signed
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.unkeyedContainer()
            
            let modeString = try container.decode(String.self)
            
            switch modeString {
            case "Disabled":
                self = .disabled
            case "Signed":
                let signedModel = try container.decode(SignedModel.self)
                self = .signed(signedModel)
            }
        }
    }
    
    typealias Signer = ExtrinsicSignatureFactoryProtocol
    
    enum Usability {
        case disabled
        case toSign(Signer, SigningParams)
    }
    
    struct SigningParams {
        let account: JSON
    }
}

extension TransactionExtension.VerifySignature: TransactionExtending {
    public var txExtensionId: String { Extrinsic.TransactionExtensionId.verifySignature }
    
    public func implicit(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> Data? {
        nil
    }
    
    public func explicit(
        for implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        switch usability {
        case .disabled:
            let value = try Mode.disabled.toScaleCompatibleJSON(with: context?.toRawContext())
            
            return try TransactionExtension.Explicit(
                from: value,
                txExtensionId: txExtensionId,
                metadata: metadata
            )
        case .toSign(let signer, let signingParams):
            let message = try signaturePayloadFactory.createPayload(
                from: implication,
                using: encodingFactory
            )
            
            let payload = try ExtrinsicSignatureConverter.convertExtrinsicPayloadToRegular(message)
            
            let signature = try signer.createSignature(from: payload, context: context)
            
            let value = try Mode
                .signed(signature: signature, account: signingParams.account)
                .toScaleCompatibleJSON(with: context?.toRawContext())
            
            return try TransactionExtension.Explicit(
                from: value,
                txExtensionId: txExtensionId,
                metadata: metadata
            )
        }
    }
}
