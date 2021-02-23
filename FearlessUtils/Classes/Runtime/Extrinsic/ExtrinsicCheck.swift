import Foundation

enum ExtrinsicCheck: String {
    case specVersion = "CheckSpecVersion"
    case txVersion = "CheckTxVersion"
    case nonce = "CheckNonce"
    case mortality = "CheckMortality"
    case genesis = "CheckGenesis"
    case txPayment = "ChargeTransactionPayment"
    case weight = "CheckWeight"
    case attests = "PrevalidateAttests"
}
