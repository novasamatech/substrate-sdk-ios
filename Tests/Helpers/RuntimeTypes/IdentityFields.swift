import Foundation

public struct IdentityFields: OptionSet, Codable {
    public static let display = IdentityFields(rawValue: 1 << 0)
    public static let legal = IdentityFields(rawValue: 1 << 1)
    public static let web = IdentityFields(rawValue: 1 << 2)
    public static let riot = IdentityFields(rawValue: 1 << 3)
    public static let email = IdentityFields(rawValue: 1 << 4)
    public static let fingerprint = IdentityFields(rawValue: 1 << 5)
    public static let image = IdentityFields(rawValue: 1 << 6)
    public static let twitter = IdentityFields(rawValue: 1 << 7)

    public typealias RawValue = UInt64

    public var rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public mutating func formUnion(_ other: IdentityFields) {
        rawValue |= other.rawValue
    }

    public mutating func formIntersection(_ other: IdentityFields) {
        rawValue &= other.rawValue
    }

    public mutating func formSymmetricDifference(_ other: IdentityFields) {
        rawValue ^= other.rawValue
    }
}
