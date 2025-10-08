import Foundation
import Operation_iOS

protocol RuntimeContainerSourceProtocol {
    var opaque: Bool { get }
    var metadata: Data { get }
}

public struct RuntimeMetadataItem: Codable & Equatable, RuntimeContainerSourceProtocol {
    public enum CodingKeys: String, CodingKey {
        case chain
        case version
        case txVersion
        case localMigratorVersion
        case opaque
        case metadata
    }

    public let chain: String
    public let version: UInt32
    public let txVersion: UInt32
    public let localMigratorVersion: UInt32
    public let opaque: Bool
    public let metadata: Data
}

extension RuntimeMetadataItem: Identifiable {
    public var identifier: String { chain }
}
