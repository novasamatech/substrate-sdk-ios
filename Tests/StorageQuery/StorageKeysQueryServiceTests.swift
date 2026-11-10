import Testing
import Foundation
import Operation_iOS
import Foundation_iOS
import SubstrateSdk
import TestHelpers
@testable import SubstrateStorageQuery

@Suite("Storage keys query service")
struct StorageKeysQueryServiceTests {
    private let prefix = Data(repeating: 0xa1, count: 32)
    private let otherPrefix = Data(repeating: 0xb2, count: 32)

    private func entries(count: Int, under prefix: Data) -> [Data: Data] {
        (0 ..< count).reduce(into: [Data: Data]()) { storage, index in
            let suffix = withUnsafeBytes(of: UInt32(index).bigEndian) { Data($0) }
            storage[prefix + suffix] = Data([UInt8(index % 251)])
        }
    }

    private func sortedKeys(of storage: [Data: Data]) -> [Data] {
        storage.keys.sorted { $0.lexicographicallyPrecedes($1) }
    }

    private func fetchKeys(
        engine: MockJSONRPCEngine,
        pageSize: UInt32 = 1000,
        blockHash: Data? = nil
    ) async throws -> [Data] {
        let prefix = self.prefix

        let service = StorageKeysQueryService(
            connection: engine,
            operationManager: OperationManager(operationQueue: OperationQueue()),
            prefixKeyClosure: { prefix },
            mapper: AnyMapper(mapper: IdentityMapper()),
            pageSize: pageSize,
            blockHash: blockHash
        )

        return try await withCheckedThrowingContinuation { continuation in
            service.start { continuation.resume(with: $0) }
        }
    }

    @Test("returns every key under the prefix when they span several pages")
    func collectsAllPages() async throws {
        // Given
        let matching = entries(count: 7, under: prefix)
        let node = FakeStorageNode(head: matching.merging(entries(count: 3, under: otherPrefix)) { first, _ in first })

        // When
        let keys = try await fetchKeys(engine: node.makeEngine(), pageSize: 3)

        // Then
        #expect(keys == sortedKeys(of: matching))
    }

    @Test("default page size walks past the node's page limit")
    func collectsBeyondNodePageLimit() async throws {
        // Given
        let matching = entries(count: Int(FakeStorageNode.maxPageCount) * 2 + 1, under: prefix)
        let node = FakeStorageNode(head: matching)

        // When
        let keys = try await fetchKeys(engine: node.makeEngine())

        // Then
        #expect(keys == sortedKeys(of: matching))
    }

    @Test("returns no keys when nothing matches the prefix")
    func emptyPrefix() async throws {
        // Given
        let node = FakeStorageNode(head: entries(count: 4, under: otherPrefix))

        // When
        let keys = try await fetchKeys(engine: node.makeEngine())

        // Then
        #expect(keys.isEmpty)
    }

    @Test("keys requested at a block come from that block's storage")
    func keysAtBlock() async throws {
        // Given
        let blockHash = Data(repeating: 0x3c, count: 32)
        let atBlock = entries(count: 5, under: prefix)
        let node = FakeStorageNode(head: entries(count: 2, under: prefix), blocks: [blockHash: atBlock])

        // When
        let keys = try await fetchKeys(engine: node.makeEngine(), pageSize: 2, blockHash: blockHash)

        // Then
        #expect(keys == sortedKeys(of: atBlock))
    }

    @Test("rpc failure fails the whole fetch")
    func rpcFailurePropagates() async throws {
        struct Boom: Error {}

        let engine = MockJSONRPCEngine { _, _ in .failure(Boom()) }

        await #expect(throws: Boom.self) {
            _ = try await fetchKeys(engine: engine)
        }
    }
}
