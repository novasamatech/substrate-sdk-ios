import Foundation

public struct RuntimeVersion: Codable, Equatable {
    let specVersion: UInt32
    let transactionVersion: UInt32
}

public struct RuntimeVersionFull: Codable, Equatable {
    public let specVersion: UInt32
    public let transactionVersion: UInt32
    public let specName: String
}
