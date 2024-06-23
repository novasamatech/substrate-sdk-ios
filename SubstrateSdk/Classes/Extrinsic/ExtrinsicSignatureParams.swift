import Foundation

public struct ExtrinsicSignatureParams {
    public let encodedCall: Data
    public let includedInExtrinsicExtra: Data
    public let includedInSignatureExtra: Data
    
    public init(encodedCall: Data, includedInExtrinsicExtra: Data, includedInSignatureExtra: Data) {
        self.encodedCall = encodedCall
        self.includedInExtrinsicExtra = includedInExtrinsicExtra
        self.includedInSignatureExtra = includedInSignatureExtra
    }
}
