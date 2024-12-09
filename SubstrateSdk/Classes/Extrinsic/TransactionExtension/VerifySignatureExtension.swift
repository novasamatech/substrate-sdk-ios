import Foundation

final class VerifySignatureExtension {
    let extensionVersion: UInt8
    let usability: VerifySignatureExtension.Usability
    
    init(
        extensionVersion: UInt8 = ExtrinsicConstants.extensionVersion,
        usability: VerifySignatureExtension.Usability
    ) {
        self.extensionVersion = extensionVersion
        self.usability = usability
    }
}

extension VerifySignatureExtension {
    enum ExplicitValue: Codable {
        case disabled
        case enabled(signature: MultiSignature, account: JSON)
    }
    
    typealias Signer = (Data) throws -> Data
    
    enum Usability {
        case disabled
        case toSign(Signer, SigningParams)
    }
    
    struct SigningParams {
        let account: JSON
        let cryptoType: CryptoType
    }
}

extension VerifySignatureExtension: TransactionExtending {
    var extensionId: String { "VerifySignature" }
    
    func implicit(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> Data? {
        nil
    }
    
    func explicit(
        for implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        guard let signedExtensionType = metadata.getSignedExtensionType(for: extensionId) else {
            return nil
        }
        
        switch usability {
        case .disabled:
            let value = try ExplicitValue.disabled.toScaleCompatibleJSON(with: context?.toRawContext())
            return TransactionExtension.Explicit(
                extensionId: extensionId,
                value: value,
                customEncoder: DefaultExtrinsicSignedExtensionCoder(
                    signedExtensionId: extensionId,
                    extraType: signedExtensionType
                )
            )
        case .toSign(let signer, let signingParams):
            let encoder = try encodingFactory.createEncoder()
            try encoder.append(encodable: extensionVersion)
            try encoder.append(json: implication.call, type: GenericType.call.name)
            
            try implication.explicits.forEach { explicit in
                try explicit.encode(to: encoder)
            }
            
            try implication.implicits.forEach { implicit in
                try encoder.appendRawData(implicit)
            }
            
            let message = try encoder.encode()
            
            let rawSignature = try signer(message)
            
            let multiSignature = switch signingParams.cryptoType {
                case .sr25519:
                    MultiSignature.sr25519(data: rawSignature)
                case .ed25519:
                    MultiSignature.ed25519(data: rawSignature)
                case .ecdsa:
                    MultiSignature.ecdsa(data: rawSignature)
            }
            
            let value = try ExplicitValue
                .enabled(signature: multiSignature, account: signingParams.account)
                .toScaleCompatibleJSON(with: context?.toRawContext())
            
            return TransactionExtension.Explicit(
                extensionId: extensionId,
                value: value,
                customEncoder: DefaultExtrinsicSignedExtensionCoder(
                    signedExtensionId: extensionId,
                    extraType: signedExtensionType
                )
            )
        }
    }
}
