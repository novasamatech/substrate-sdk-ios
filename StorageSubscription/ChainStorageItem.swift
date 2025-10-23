import Foundation
import Operation_iOS

public struct ChainStorageItem: Codable, Identifiable, Equatable {
    enum CodingKeys: String, CodingKey {
        case identifier
        case data
    }

    public let identifier: String
    public let data: Data
    
    public init(identifier: String, data: Data) {
        self.identifier = identifier
        self.data = data
    }
}
