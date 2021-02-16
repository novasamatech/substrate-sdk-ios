import Foundation

public enum KnownType: String, CaseIterable {
    case balance = "BalanceOf"
    case index = "Index"
    case phase = "Phase"
    case call = "Call"
    case address = "Address"
    case signature = "MultiSignature"

    public var name: String { rawValue }
}
