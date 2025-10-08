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
    
    func asset(for assetId: AssetId) -> AssetProtocol?
    
    func chainAsset(for assetId: AssetId) -> ChainAssetProtocol?
    
    func address(for accountId: AccountId) throws -> AccountAddress
    
    func utilityChainAssetId() -> ChainAssetIdProtocol?
}

public extension ChainProtocol {
    func utilityAsset() -> AssetProtocol? {
        guard let utilityChainAssetId = utilityChainAssetId() else {
            return nil
        }
        
        return asset(for: utilityChainAssetId.assetId)
    }
}

public protocol AssetProtocol {
    var assetId: AssetId { get }
    
    var isUtility: Bool { get }
    
    var decimalPrecision: UInt8 { get }
    
    var symbol: String { get }
}

public protocol ChainAssetIdProtocol {
    var chainId: ChainId { get }
    var assetId: AssetId { get }
}

public protocol ChainAssetProtocol {
    
}
