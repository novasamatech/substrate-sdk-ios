import Foundation
import SubstrateSdk

public struct Event: Decodable {
    public let moduleIndex: UInt8
    public let eventIndex: UInt32
    public let params: JSON

    public init(from decoder: Decoder) throws {
        var unkeyedContainer = try decoder.unkeyedContainer()

        moduleIndex = try unkeyedContainer.decode(UInt8.self)
        eventIndex = try unkeyedContainer.decode(UInt32.self)
        params = try unkeyedContainer.decode(JSON.self)
    }
}
