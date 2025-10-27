import Foundation
import BigInt

public extension SystemPallet {
    struct AccountInfo: Codable, Equatable {
        @StringCodable public var nonce: UInt32
        @OptionStringCodable public var consumers: UInt32?
        @OptionStringCodable public var providers: UInt32?
        public let data: AccountData

        public var hasConsumers: Bool {
            (consumers ?? 0) > 0
        }

        public var hasProviders: Bool {
            (providers ?? 0) > 0
        }
    }

    struct AccountData: Codable, Equatable {
        @StringCodable public var free: BigUInt
        @StringCodable public var reserved: BigUInt
        @OptionStringCodable public var frozen: BigUInt?
        @OptionStringCodable public var miscFrozen: BigUInt?
        @OptionStringCodable public var feeFrozen: BigUInt?
        @OptionStringCodable public var flags: BigUInt?
    }
}

public extension SystemPallet.AccountData {
    var total: BigUInt { free + reserved }

    var locked: BigUInt {
        if let feeFrozen, let miscFrozen {
            max(miscFrozen, feeFrozen)
        } else {
            frozen ?? 0
        }
    }

    var available: BigUInt { free > locked ? free - locked : 0 }
}
