import Foundation

public extension Extrinsic {
    enum SignedExtensionId: String {
        case specVersion = "CheckSpecVersion"
        case txVersion = "CheckTxVersion"
        case nonce = "CheckNonce"
        case mortality = "CheckMortality"
        case genesis = "CheckGenesis"
        case txPayment = "ChargeTransactionPayment"
        case assetTxPayment = "ChargeAssetTxPayment"
        case checkMetadataHash = "CheckMetadataHash"
        case weight = "CheckWeight"
        case attests = "PrevalidateAttests"
    }
}
