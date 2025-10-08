import Foundation
import Operation_iOS

public protocol RuntimeMetadataItemProtocol {
    var version: UInt32 { get }
    var metadata: Data { get }
}
