import Testing
import Foundation
import Operation_iOS
import SubstrateSdk
import TestHelpers
@testable import SubstrateStorageQuery

@Suite("Storage request factory prefix query")
struct StorageRequestFactoryPrefixTests {
    private static let accountInfoSize = 80

    private static func makeCoderFactory() throws -> RuntimeCoderFactoryProtocol {
        let fileName = "polkadot-v14-metadata"
        let metadata = try PostV14RuntimeHelper.createMetadata(for: fileName)
        let catalog = try PostV14RuntimeHelper.createTypeRegistry(from: fileName)

        return RuntimeCoderFactory(catalog: catalog, specVersion: 0, txVersion: 0, metadata: metadata)
    }

    private static func systemAccounts(count: Int) throws -> (storage: [Data: Data], accountIds: Set<AccountId>) {
        let keyFactory = StorageKeyFactory()
        var storage = [Data: Data]()
        var accountIds = Set<AccountId>()

        for index in 0 ..< count {
            var accountId = Data(repeating: 0, count: 32)
            withUnsafeBytes(of: UInt32(index).bigEndian) { accountId.replaceSubrange(28 ..< 32, with: $0) }

            let key = try keyFactory.createStorageKey(
                moduleName: SystemPallet.accountPath.moduleName,
                storageName: SystemPallet.accountPath.itemName,
                key: accountId,
                hasher: .blake128Concat
            )

            storage[key] = Data(repeating: 0, count: accountInfoSize)
            accountIds.insert(accountId)
        }

        return (storage, accountIds)
    }

    @Test("every account under the prefix is returned for the requested block")
    func pagesAtBlock() throws {
        // Given
        let blockHash = Data(repeating: 0x11, count: 32)
        let atBlock = try Self.systemAccounts(count: 2500)
        let head = try Self.systemAccounts(count: 3)
        let node = FakeStorageNode(head: head.storage, blocks: [blockHash: atBlock.storage])

        let coderFactory = try Self.makeCoderFactory()
        let operationQueue = OperationQueue()
        let factory = StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: OperationManager(operationQueue: operationQueue)
        )

        let wrapper: CompoundOperationWrapper<[AccountIdKey: SystemPallet.AccountInfo]> = factory.queryByPrefix(
            engine: node.makeEngine(),
            request: UnkeyedRemoteStorageRequest(storagePath: SystemPallet.accountPath),
            storagePath: SystemPallet.accountPath,
            factory: { coderFactory },
            options: StorageQueryListOptions(atBlock: blockHash)
        )

        // When
        operationQueue.addOperations(wrapper.allOperations, waitUntilFinished: true)
        let result = try wrapper.targetOperation.extractNoCancellableResultData()

        // Then
        #expect(result.count == atBlock.accountIds.count)
        #expect(Set(result.keys.map(\.accountId)) == atBlock.accountIds)
        #expect(result.values.allSatisfy { $0.nonce == 0 && $0.data.free == 0 })
    }
}
