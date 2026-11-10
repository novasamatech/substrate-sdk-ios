import Foundation
import SubstrateSdk
import TestHelpers

enum FakeStorageNodeError: Error {
    case unsupportedMethod(String)
    case malformedParams(String)
    case invalidCount(UInt64)
}

// In-memory node answering only the safe storage RPCs: keys are served in pages,
// values per block, anything else is rejected like a `--rpc-methods=safe` node would.
final class FakeStorageNode {
    static let maxPageCount: UInt64 = 1000

    let headHash: Data
    private let head: [Data: Data]
    private let blocks: [Data: [Data: Data]]

    init(head: [Data: Data], blocks: [Data: [Data: Data]] = [:]) {
        self.head = head
        self.blocks = blocks
        headHash = Data(repeating: 0xee, count: 32)
    }

    func makeEngine() -> MockJSONRPCEngine {
        MockJSONRPCEngine { [self] call, _ in respond(to: call) }
    }

    private func respond(to call: MockJSONRPCEngine.RecordedCall) -> Result<JSON, Error> {
        Result {
            switch call.method {
            case RPCMethod.getStorageKeysPaged:
                return try keysPaged(params: call.params)
            case RPCMethod.queryStorageAt:
                return try queryStorageAt(params: call.params)
            default:
                throw FakeStorageNodeError.unsupportedMethod(call.method)
            }
        }
    }

    private func storage(at blockHashHex: String?) throws -> [Data: Data] {
        guard let blockHashHex else {
            return head
        }

        let blockHash = try Data(hexString: blockHashHex)

        if blockHash == headHash {
            return head
        }

        guard let storage = blocks[blockHash] else {
            throw FakeStorageNodeError.malformedParams("unknown block \(blockHashHex)")
        }

        return storage
    }

    private func keysPaged(params: JSON?) throws -> JSON {
        guard
            let params = params?.arrayValue,
            params.count == 4,
            let prefixHex = params[0].stringValue,
            let count = params[1].unsignedIntValue
        else {
            throw FakeStorageNodeError.malformedParams("state_getKeysPaged expects [prefix, count, start_key, at]")
        }

        guard count <= Self.maxPageCount else {
            throw FakeStorageNodeError.invalidCount(count)
        }

        let prefix = try Data(hexString: prefixHex)
        let startKey = try params[2].stringValue.map { try Data(hexString: $0) }
        let storage = try storage(at: params[3].stringValue)

        let page = storage.keys
            .filter { $0.starts(with: prefix) }
            .filter { key in startKey.map { $0.lexicographicallyPrecedes(key) } ?? true }
            .sorted { $0.lexicographicallyPrecedes($1) }
            .prefix(Int(count))

        return .arrayValue(page.map { .stringValue($0.toHex(includePrefix: true)) })
    }

    private func queryStorageAt(params: JSON?) throws -> JSON {
        guard
            let params = params?.arrayValue,
            (1 ... 2).contains(params.count),
            let keys = params[0].arrayValue
        else {
            throw FakeStorageNodeError.malformedParams("state_queryStorageAt expects [keys, at]")
        }

        let blockHashHex = params.count == 2 ? params[1].stringValue : nil
        let storage = try storage(at: blockHashHex)

        let changes: [JSON] = try keys.map { keyJson in
            guard let keyHex = keyJson.stringValue else {
                throw FakeStorageNodeError.malformedParams("key must be hex string")
            }

            let value = storage[try Data(hexString: keyHex)]

            return .arrayValue([
                .stringValue(keyHex),
                value.map { .stringValue($0.toHex(includePrefix: true)) } ?? .null
            ])
        }

        return .arrayValue([
            .dictionaryValue([
                "block": .stringValue(blockHashHex ?? headHash.toHex(includePrefix: true)),
                "changes": .arrayValue(changes)
            ])
        ])
    }
}
