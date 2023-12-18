import Foundation

public enum KnownType: String, CaseIterable {
    case balance = "Balance"
    case index = "Index"
    case phase = "Phase"
    case call = "GenericCall"
    case event = "GenericEvent"
    case address = "Address"
    case signature = "ExtrinsicSignature"
    case runtimeDispatchInfo = "RuntimeDispatchInfo"

    public var name: String { rawValue }
}
