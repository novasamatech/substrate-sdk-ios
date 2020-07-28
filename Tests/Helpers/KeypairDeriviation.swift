import Foundation

struct KeypairDeriviation: Decodable {
    enum CodingKeys: String, CodingKey {
        case publicKey = "pk"
        case path
        case mnemonic
    }

    let mnemonic: String
    let publicKey: String
    let path: String
}
