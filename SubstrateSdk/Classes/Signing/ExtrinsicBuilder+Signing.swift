import Foundation

enum ExtrinsicBuilderExtensionError: Error {
    case invalidResolvedAccount
    case invalidRawSignature(data: Data)
}

public extension ExtrinsicBuilderProtocol {
    func signing(
        with signingClosure: @escaping (Data, SigningContext) throws -> Data,
        context: SigningContext.SubstrateExtrinsic,
        codingFactory: RuntimeCoderFactoryProtocol
    ) throws -> Self {
        guard let account = context.signerProvider.account else {
            throw ExtrinsicBuilderExtensionError.invalidResolvedAccount
        }

        return switch account.signatureFormat {
        case .ethereum:
            try signing(
                by: { data in
                    let signature = try signingClosure(data, .substrateExtrinsic(context))

                    guard let ethereumSignature = EthereumSignature(rawValue: signature) else {
                        throw ExtrinsicBuilderExtensionError.invalidRawSignature(data: signature)
                    }

                    return try ethereumSignature.toScaleCompatibleJSON(
                        with: codingFactory.createRuntimeJsonContext().toRawContext()
                    )
                },
                using: codingFactory,
                metadata: codingFactory.metadata
            )
        case .substrate:
            try signing(
                by: { data in
                    try signingClosure(data, .substrateExtrinsic(context))
                },
                of: account.signatureType,
                using: codingFactory,
                metadata: codingFactory.metadata
            )
        }
    }
}
