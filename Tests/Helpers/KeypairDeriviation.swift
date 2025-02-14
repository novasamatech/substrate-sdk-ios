import Foundation
import NovaCrypto

public struct KeypairDeriviation: Decodable {
    enum CodingKeys: String, CodingKey {
        case publicKey = "pk"
        case path
        case mnemonic
        case seed
    }

    public let mnemonic: String
    public let publicKey: String
    public let path: String
    public let seed: String
}

public enum KnownChainType: UInt16 {
    case polkadotMain = 0
    case polkadotSecondary = 1
    case kusamaMain = 2
    case kusamaSecondary = 3
    case genericSubstrate = 42
}
