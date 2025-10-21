import Foundation
import BigInt

public typealias ChainId = String
public typealias AssetId = UInt64

public protocol ChainProtocol {
    var chainId: ChainId { get }
    
    var feeViaRuntimeCall: Bool { get }
    
    var disabledCheckMetadataHash: Bool { get }
    
    var defaultTip: BigUInt? { get }
    
    var base58Prefix: UInt16 { get }
    
    var isRelaychain: Bool { get }
    
    func asset(for assetId: AssetId) -> AssetProtocol?
    
    func chainAsset(for assetId: AssetId) -> ChainAssetProtocol?
    func chainAssets() -> [ChainAssetProtocol]
    
    func address(for accountId: AccountId) throws -> AccountAddress
    
    func utilityChainAssetId() -> ChainAssetId?
}

public extension ChainProtocol {
    func utilityAsset() -> AssetProtocol? {
        guard let utilityChainAssetId = utilityChainAssetId() else {
            return nil
        }
        
        return asset(for: utilityChainAssetId.assetId)
    }
    
    func utilityChainAsset() -> ChainAssetProtocol? {
        guard let utilityChainAssetId = utilityChainAssetId() else {
            return nil
        }
        
        return chainAsset(for: utilityChainAssetId.assetId)
    }
}

public protocol AssetProtocol {
    var assetId: AssetId { get }
    
    var isUtility: Bool { get }
    
    var decimalPrecision: UInt8 { get }
    
    var symbol: String { get }
}

public struct ChainAssetId: Equatable, Codable, Hashable {
    public let chainId: ChainId
    public let assetId: AssetId

    public var stringValue: String { "\(chainId)-\(assetId)" }

    public init(chainId: ChainId, assetId: AssetId) {
        self.chainId = chainId
        self.assetId = assetId
    }
}

public protocol ChainAssetProtocol {
    var chain: ChainProtocol { get }
    var asset: AssetProtocol { get }
    var chainAssetId: ChainAssetId { get }
}
