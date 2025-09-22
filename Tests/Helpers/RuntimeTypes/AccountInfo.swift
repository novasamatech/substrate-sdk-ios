import Foundation
import BigInt
import SubstrateSdk

public struct AccountInfo: Codable, Equatable {
    @StringCodable public var nonce: UInt32
    @StringCodable public var consumers: UInt32
    @StringCodable public var providers: UInt32
    public let data: AccountData
    
    public init(
        nonce: UInt32,
        consumers: UInt32,
        providers: UInt32,
        data: AccountData
    ) {
        self.nonce = nonce
        self.consumers = consumers
        self.providers = providers
        self.data = data
    }
}

public struct AccountInfoV14: Codable, Equatable {
    @StringCodable public var nonce: UInt32
    @StringCodable public var consumers: UInt32
    @StringCodable public var providers: UInt32
    @StringCodable public var sufficients: UInt32
    public let data: AccountData
    
    public init(
        nonce: UInt32,
        consumers: UInt32,
        providers: UInt32,
        sufficients: UInt32,
        data: AccountData
    ) {
        self.nonce = nonce
        self.consumers = consumers
        self.providers = providers
        self.sufficients = sufficients
        self.data = data
    }
}

public struct AccountData: Codable, Equatable {
    @StringCodable public var free: BigUInt
    @StringCodable public var reserved: BigUInt
    @StringCodable public var miscFrozen: BigUInt
    @StringCodable public var feeFrozen: BigUInt
    
    public init(
        free: BigUInt,
        reserved: BigUInt,
        miscFrozen: BigUInt,
        feeFrozen: BigUInt
    ) {
        self.free = free
        self.reserved = reserved
        self.miscFrozen = miscFrozen
        self.feeFrozen = feeFrozen
    }
}
