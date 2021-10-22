import Foundation

struct IdentityFields: OptionSet, Codable {
    static let display = IdentityFields(rawValue: 1 << 0)
    static let legal = IdentityFields(rawValue: 1 << 1)
    static let web = IdentityFields(rawValue: 1 << 2)
    static let riot = IdentityFields(rawValue: 1 << 3)
    static let email = IdentityFields(rawValue: 1 << 4)
    static let fingerprint = IdentityFields(rawValue: 1 << 5)
    static let image = IdentityFields(rawValue: 1 << 6)
    static let twitter = IdentityFields(rawValue: 1 << 7)

    typealias RawValue = UInt64

    var rawValue: RawValue

    init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    mutating func formUnion(_ other: IdentityFields) {
        rawValue |= other.rawValue
    }

    mutating func formIntersection(_ other: IdentityFields) {
        rawValue &= other.rawValue
    }

    mutating func formSymmetricDifference(_ other: IdentityFields) {
        rawValue ^= other.rawValue
    }
}
