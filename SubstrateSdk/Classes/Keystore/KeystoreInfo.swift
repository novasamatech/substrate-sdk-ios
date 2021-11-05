import Foundation
import IrohaCrypto

public struct KeystoreInfo {
    public let address: String?
    public let chainType: ChainType?
    public let secretType: KeystoreSecretType
    public let meta: KeystoreMeta?
}
