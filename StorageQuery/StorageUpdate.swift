import Foundation

public struct StorageUpdate: Decodable {
    public enum CodingKeys: String, CodingKey {
        case blockHash = "block"
        case changes
    }

    public let blockHash: String?
    public let changes: [[String?]]?
    
    public init(blockHash: String?, changes: [[String?]]?) {
        self.blockHash = blockHash
        self.changes = changes
    }
}

public struct StorageUpdateData {
    public struct StorageUpdateChangeData {
        public let key: Data
        public let value: Data?

        public init?(change: [String?]) {
            guard change.count == 2 else {
                return nil
            }

            guard let keyString = change[0], let keyData = try? Data(hexString: keyString) else {
                return nil
            }

            key = keyData

            if let valueString = change[1], let valueData = try? Data(hexString: valueString) {
                value = valueData
            } else {
                value = nil
            }
        }
    }

    public let blockHash: Data?
    public let changes: [StorageUpdateChangeData]

    public init(update: StorageUpdate) {
        if
            let blockHashString = update.blockHash,
            let blockHashData = try? Data(hexString: blockHashString) {
            blockHash = blockHashData
        } else {
            blockHash = nil
        }

        changes = update.changes?.compactMap { StorageUpdateChangeData(change: $0) } ?? []
    }

    public func getChangesOrdered(by keys: [Data]) -> [StorageUpdateChangeData] {
        let keyedChanges = changes.reduce(into: [Data: StorageUpdateChangeData]()) { accum, change in
            accum[change.key] = change
        }

        return keys.reduce([StorageUpdateChangeData]()) { accum, key in
            guard let change = keyedChanges[key] else {
                return accum
            }

            return accum + [change]
        }
    }
}
