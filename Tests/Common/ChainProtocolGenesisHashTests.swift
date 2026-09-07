import XCTest
import BigInt
@testable import SubstrateSdk

class ChainProtocolGenesisHashTests: XCTestCase {

    private struct StubChain: ChainProtocol {
        let chainId: ChainId

        var name: String { "Stub" }
        var parentId: ChainId? { nil }
        var feeViaRuntimeCall: Bool { false }
        var disabledCheckMetadataHash: Bool { false }
        var defaultTip: BigUInt? { nil }
        var base58Prefix: UInt16 { 0 }
        var isRelaychain: Bool { false }
        var isEthereumBased: Bool { false }

        func assetInteface(for _: AssetId) -> AssetProtocol? { nil }
        func chainAssetInterface(for _: AssetId) -> ChainAssetProtocol? { nil }
        func chainAssetsInterface() -> [ChainAssetProtocol] { [] }
        func address(for _: AccountId) throws -> AccountAddress { "" }
        func utilityChainAssetId() -> ChainAssetId? { nil }
    }

    private struct OverridingChain: ChainProtocol {
        let chainId: ChainId
        let genesisHash: ChainId

        var name: String { "Overriding" }
        var parentId: ChainId? { nil }
        var feeViaRuntimeCall: Bool { false }
        var disabledCheckMetadataHash: Bool { false }
        var defaultTip: BigUInt? { nil }
        var base58Prefix: UInt16 { 0 }
        var isRelaychain: Bool { false }
        var isEthereumBased: Bool { false }

        func assetInteface(for _: AssetId) -> AssetProtocol? { nil }
        func chainAssetInterface(for _: AssetId) -> ChainAssetProtocol? { nil }
        func chainAssetsInterface() -> [ChainAssetProtocol] { [] }
        func address(for _: AccountId) throws -> AccountAddress { "" }
        func utilityChainAssetId() -> ChainAssetId? { nil }
    }

    func testGenesisHashDefaultsToChainId() {
        let chain = StubChain(chainId: "release-people")

        XCTAssertEqual(chain.genesisHash, "release-people")
        XCTAssertEqual(chain.genesisHash, chain.chainId)
    }

    func testGenesisHashUsesOverrideWhenProvided() {
        let genesisHash = "0x1234567890abcdef"
        let chain = OverridingChain(chainId: "release-people", genesisHash: genesisHash)

        XCTAssertEqual(chain.genesisHash, genesisHash)
        XCTAssertNotEqual(chain.genesisHash, chain.chainId)
    }
}
