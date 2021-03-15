import Foundation

struct SessionKeysPolkadot: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case grandpa
        case babe
        case imOnline = "im_online"
        case authorityDiscovery = "authority_discovery"
        case parachains
    }

    let grandpa: Data
    let babe: Data
    let imOnline: Data
    let authorityDiscovery: Data
    let parachains: Data
}
