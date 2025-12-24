import Foundation
import BigInt

public typealias ChainId = String
public typealias AssetId = UInt64

public protocol ChainProtocol {
    var chainId: ChainId { get }
    
    var name: String { get }

    var parentId: ChainId? { get }
    
    var feeViaRuntimeCall: Bool { get }
    
    var disabledCheckMetadataHash: Bool { get }
    
    var defaultTip: BigUInt? { get }
    
    var base58Prefix: UInt16 { get }
    
    var isRelaychain: Bool { get }
    
    var isEthereumBased: Bool { get }
    
    func assetInteface(for assetId: AssetId) -> AssetProtocol?
    
    func chainAssetInterface(for assetId: AssetId) -> ChainAssetProtocol?
    
    func chainAssetsInterface() -> [ChainAssetProtocol]
    
    func address(for accountId: AccountId) throws -> AccountAddress
    
    func utilityChainAssetId() -> ChainAssetId?
}

public extension ChainProtocol {
    func utilityAssetInterface() -> AssetProtocol? {
        guard let utilityChainAssetId = utilityChainAssetId() else {
            return nil
        }
        
        return assetInteface(for: utilityChainAssetId.assetId)
    }
    
    func utilityChainAssetInterface() -> ChainAssetProtocol? {
        guard let utilityChainAssetId = utilityChainAssetId() else {
            return nil
        }
        
        return chainAssetInterface(for: utilityChainAssetId.assetId)
    }
    
    var accountIdSize: Int {
        isEthereumBased ? 20 : 32
    }

    func chainAssetInterfaceForSymbol(_ symbol: String) -> ChainAssetProtocol? {
        chainAssetsInterface().first { $0.assetInterface.symbol == symbol }
    }

    func chainAssetInterfaceOrError(for assetId: AssetId) throws -> ChainAssetProtocol {
        guard let chainAsset = chainAssetInterface(for: assetId) else {
            throw ChainError.noAsset(assetId: assetId)
        }

        return chainAsset
    }

    func utilityChainAssetInterfaceOrError() throws -> ChainAssetProtocol {
        guard let nativeAsset = utilityChainAssetInterface() else {
            throw ChainError.noUtilityAsset
        }

        return nativeAsset
    }

    func emptyAccountId() throws -> AccountId {
        try Data.randomOrError(of: accountIdSize)
    }
}

public enum ChainError: Error {
    case noAsset(assetId: AssetId)
    case noUtilityAsset
}

public protocol AssetProtocol {
    var assetId: AssetId { get }
    
    var isUtility: Bool { get }
    
    var decimalPrecision: Int16 { get }
    
    var symbol: String { get }
}

public struct ChainAssetId: Equatable, Codable, Hashable, Sendable {
    public let chainId: ChainId
    public let assetId: AssetId

    public var stringValue: String { "\(chainId)-\(assetId)" }

    public init(chainId: ChainId, assetId: AssetId) {
        self.chainId = chainId
        self.assetId = assetId
    }
}

public protocol ChainAssetProtocol {
    var chainInterface: ChainProtocol { get }
    var assetInterface: AssetProtocol { get }
    var chainAssetId: ChainAssetId { get }
}
