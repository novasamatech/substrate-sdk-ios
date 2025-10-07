import Foundation

public protocol Mapping {
    associatedtype InputType
    associatedtype OutputType

    func map(input: InputType) -> OutputType
}

public class AnyMapper<T, R>: Mapping {
    public typealias InputType = T
    public typealias OutputType = R

    private let privateMap: (T) -> R

    init<U: Mapping>(mapper: U) where U.InputType == InputType, U.OutputType == OutputType {
        privateMap = mapper.map
    }

    public func map(input: InputType) -> OutputType {
        privateMap(input)
    }
}
