import Foundation

public protocol PostV14PalletMetadataProtocol {
    var name: String { get }
    var storage: StorageMetadataV14? { get }
    var calls: CallMetadataV14? { get }
    var events: EventMetadataV14? { get }
    var constants: [ConstantMetadataV14] { get }
    var errors: ErrorMetadataV14? { get }
    var index: UInt8 { get }
}
