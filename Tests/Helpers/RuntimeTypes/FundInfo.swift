import Foundation
import BigInt
import SubstrateSdk

public struct FundInfo: Codable, Equatable {
    public let retiring: Bool
    public let depositor: Data
    @NullCodable public var verifier: MultiSigner?
    @StringCodable public var deposit: BigUInt
    @StringCodable public var raised: BigUInt
    @StringCodable public var end: UInt32
    @StringCodable public var cap: BigUInt
    public let lastContribution: LastContribution
    @StringCodable public var firstSlot: UInt32
    @StringCodable public var lastSlot: UInt32
    @StringCodable public var trieIndex: UInt32
    
    public init(
        retiring: Bool,
        depositor: Data,
        verifier: MultiSigner? = nil,
        deposit: BigUInt,
        raised: BigUInt,
        end: UInt32,
        cap: BigUInt,
        lastContribution: LastContribution,
        firstSlot: UInt32,
        lastSlot: UInt32,
        trieIndex: UInt32
    ) {
        self.retiring = retiring
        self.depositor = depositor
        self.verifier = verifier
        self.deposit = deposit
        self.raised = raised
        self.end = end
        self.cap = cap
        self.lastContribution = lastContribution
        self.firstSlot = firstSlot
        self.lastSlot = lastSlot
        self.trieIndex = trieIndex
    }
}

public struct FundInfoV14: Codable, Equatable {
    @BytesCodable public var depositor: Data
    @NullCodable public var verifier: MultiSigner?
    @StringCodable public var deposit: BigUInt
    @StringCodable public var raised: BigUInt
    @StringCodable public var end: UInt32
    @StringCodable public var cap: BigUInt
    public let lastContribution: LastContribution
    @StringCodable public var firstPeriod: UInt32
    @StringCodable public var lastPeriod: UInt32
    @StringCodable public var trieIndex: UInt32
    
    public init(
        depositor: Data,
        verifier: MultiSigner? = nil,
        deposit: BigUInt,
        raised: BigUInt,
        end: UInt32,
        cap: BigUInt,
        lastContribution: LastContribution,
        firstPeriod: UInt32,
        lastPeriod: UInt32,
        trieIndex: UInt32
    ) {
        self.depositor = depositor
        self.verifier = verifier
        self.deposit = deposit
        self.raised = raised
        self.end = end
        self.cap = cap
        self.lastContribution = lastContribution
        self.firstPeriod = firstPeriod
        self.lastPeriod = lastPeriod
        self.trieIndex = trieIndex
    }
}
