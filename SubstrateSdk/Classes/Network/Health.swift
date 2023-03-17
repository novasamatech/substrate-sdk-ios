import Foundation

public enum HealthCheckMethod {
    case substrate
    case websocketPingPong
}

public struct SubstrateHealthResult: Decodable {
    let isSyncing: Bool
    let peers: Int
    let shouldHavePeers: Bool
}
