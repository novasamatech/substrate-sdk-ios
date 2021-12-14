import Foundation
import BigInt
import SubstrateSdk

struct FundInfo: Codable, Equatable {
    let retiring: Bool
    let depositor: Data
    @NullCodable var verifier: MultiSigner?
    @StringCodable var deposit: BigUInt
    @StringCodable var raised: BigUInt
    @StringCodable var end: UInt32
    @StringCodable var cap: BigUInt
    let lastContribution: LastContribution
    @StringCodable var firstSlot: UInt32
    @StringCodable var lastSlot: UInt32
    @StringCodable var trieIndex: UInt32
}

struct FundInfoV14: Codable, Equatable {
    let depositor: Data
    @NullCodable var verifier: MultiSigner?
    @StringCodable var deposit: BigUInt
    @StringCodable var raised: BigUInt
    @StringCodable var end: UInt32
    @StringCodable var cap: BigUInt
    let lastContribution: LastContribution
    @StringCodable var firstPeriod: UInt32
    @StringCodable var lastPeriod: UInt32
    @StringCodable var trieIndex: UInt32
}
