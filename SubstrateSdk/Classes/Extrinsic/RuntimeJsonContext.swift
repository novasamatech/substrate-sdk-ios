import Foundation

public struct RuntimeJsonContext {
    // swiftlint:disable:next force_unwrapping
    static let addressPrefsKey = CodingUserInfoKey(rawValue: "prefersRawAddress")!

    public let prefersRawAddress: Bool

    public init(prefersRawAddress: Bool) {
        self.prefersRawAddress = prefersRawAddress
    }

    public init(rawContext: [CodingUserInfoKey: Any]) {
        if let prefersRawAddress = rawContext[Self.addressPrefsKey] as? Bool {
            self.prefersRawAddress = prefersRawAddress
        } else {
            self.prefersRawAddress = false
        }
    }

    public func toRawContext() -> [CodingUserInfoKey: Any] {
        [
            Self.addressPrefsKey: prefersRawAddress
        ]
    }
}
