import Foundation
import BigInt

public protocol ExtrinsicBuilderMemoProtocol {
    func restoreBuilder() -> ExtrinsicBuilderProtocol
}

struct ExtrinsicBuilderMemo {
    let specVersion: UInt32
    let transactionVersion: UInt32
    let genesisHash: String
    let calls: [JSON]
    let blockHash: String
    let address: JSON?
    let nonce: UInt32
    let era: Era
    let tip: BigUInt
    let signature: ExtrinsicSignature?
    let signaturePayloadFormat: ExtrinsicSignaturePayloadFormat
    let metadataHash: Data?
    let batchType: ExtrinsicBatch
    let runtimeJsonContext: RuntimeJsonContext?
    let additionalExtensions: [ExtrinsicSignedExtending]
}

extension ExtrinsicBuilderMemo: ExtrinsicBuilderMemoProtocol {
    func restoreBuilder() -> ExtrinsicBuilderProtocol {
        ExtrinsicBuilder(memo: self)
    }
}
