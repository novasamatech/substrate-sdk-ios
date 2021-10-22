import Foundation

struct KeypairDeriviation: Decodable {
    enum CodingKeys: String, CodingKey {
        case publicKey = "pk"
        case path
        case mnemonic
        case seed
    }

    let mnemonic: String
    let publicKey: String
    let path: String
    let seed: String
}

enum KnownChainType: UInt16 {
    case polkadotMain = 0
    case polkadotSecondary = 1
    case kusamaMain = 2
    case kusamaSecondary = 3
    case soraMain = 69
    case genericSubstrate = 42
}
