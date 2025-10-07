import Foundation

public final class IdentityMapper: Mapping {
    public typealias InputType = Data
    public typealias OutputType = Data

    public func map(input: InputType) -> OutputType {
        input
    }
}
