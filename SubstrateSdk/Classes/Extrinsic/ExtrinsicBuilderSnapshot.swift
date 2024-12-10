import Foundation
import BigInt

public protocol ExtrinsicBuilderMemoProtocol {
    func restoreBuilder() -> ExtrinsicBuilderProtocol
}

struct ExtrinsicBuilderMemo {
    let extrinsicVersion: Extrinsic.Version
    let extrinsic: Extrinsic?
    let address: JSON?
    let calls: [JSON]
    let batchType: ExtrinsicBatch = .atomic
    let transactionExtensions: [String: TransactionExtending]
    let signaturePayloadFormat: ExtrinsicSignaturePayloadFormat
    let runtimeJsonContext: RuntimeJsonContext?
}

extension ExtrinsicBuilderMemo: ExtrinsicBuilderMemoProtocol {
    func restoreBuilder() -> ExtrinsicBuilderProtocol {
        ExtrinsicBuilder(memo: self)
    }
}
