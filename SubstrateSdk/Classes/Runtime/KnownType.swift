import Foundation

public enum KnownType: String, CaseIterable {
    case balance = "Balance"
    case index = "Index"
    case phase = "Phase"
    case call = "GenericCall"
    case address = "Address"
    case signature = "ExtrinsicSignature"

    public var name: String { rawValue }
}
