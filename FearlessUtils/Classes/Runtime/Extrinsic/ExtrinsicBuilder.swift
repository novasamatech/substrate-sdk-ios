import Foundation
import BigInt

struct InternalCall: Codable {
    let moduleName: String
    let callName: String
    let args: JSON
}

public final class ExtrinsicBuilder {
    private let specVersion: UInt32
    private let transactionVersion: UInt32
    private let genesisHash: String

    private var calls: [InternalCall]
    private var blockHash: String
    private var nonce: UInt32
    private var era: Era
    private var tip: BigUInt

    public init(specVersion: UInt32,
                transactionVersion: UInt32,
                genesisHash: String) {
        self.specVersion = specVersion
        self.transactionVersion = transactionVersion
        self.genesisHash = genesisHash
        self.blockHash = genesisHash
        self.nonce = 0
        self.era = .immortal
        self.tip = 0
        self.calls = []
    }

    public func add<T: RuntimeCallable>(call: T) -> Self {
        self
    }
}
