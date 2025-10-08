import Foundation

public enum SigningContext {
    public struct SubstrateExtrinsic {
        public let signerProvider: SignerProviding
        public let extrinsicMemo: ExtrinsicBuilderMemoProtocol
        public let codingFactory: RuntimeCoderFactoryProtocol
        
        public init(
            signerProvider: SignerProviding,
            extrinsicMemo: ExtrinsicBuilderMemoProtocol,
            codingFactory: RuntimeCoderFactoryProtocol
        ) {
            self.signerProvider = signerProvider
            self.extrinsicMemo = extrinsicMemo
            self.codingFactory = codingFactory
        }
    }

    case substrateExtrinsic(SubstrateExtrinsic)
    case evmTransaction(SignerProviding)
    case rawBytes(SignerProviding)
    
    var signerProvider: SignerProviding {
        switch self {
        case let .substrateExtrinsic(substrate):
            substrate.signerProvider
        case let .evmTransaction(signerProvider):
            signerProvider
        case let .rawBytes(signerProvider):
            signerProvider
        }
    }
}
