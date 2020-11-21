import Foundation
import IrohaCrypto

public struct KeystoreInfo {
    public let address: String?
    public let addressType: SNAddressType?
    public let cryptoType: CryptoType
    public let meta: KeystoreMeta?
}
