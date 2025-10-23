import Foundation
import Foundation_iOS

public extension UncertainStorage where T: Decodable {
    init(
        values: [BatchStorageSubscriptionResultValue],
        mappingKey: String,
        context: [CodingUserInfoKey: Any]?
    ) throws {
        if let wrappedValue = values.first(where: { $0.mappingKey == mappingKey }) {
            let value = try wrappedValue.value.map(to: T.self, with: context)
            self = .defined(value)
        } else {
            self = .undefined
        }
    }
}
