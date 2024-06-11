import Foundation

public extension Extrinsic {
    enum SignedExtensionId {
        public static let specVersion = "CheckSpecVersion"
        public static let txVersion = "CheckTxVersion"
        public static let nonce = "CheckNonce"
        public static let mortality = "CheckMortality"
        public static let genesis = "CheckGenesis"
        public static let txPayment = "ChargeTransactionPayment"
        public static let assetTxPayment = "ChargeAssetTxPayment"
        public static let checkMetadataHash = "CheckMetadataHash"
        public static let weight = "CheckWeight"
        public static let attests = "PrevalidateAttests"
    }
}
