import Foundation

@propertyWrapper
public struct JSONRPCSubscriptionId: Decodable {
    public var wrappedValue: String

    public init(value: String = "") {
        wrappedValue = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            wrappedValue = stringValue
        } else {
            let intValue = try container.decode(Int.self)
            wrappedValue = String(intValue)
        }
    }
}
