import Foundation
import SubstrateSdk

public enum JSONListConvertibleError: Error {
    case unexpectedNumberOfItems(expected: Int, actual: Int)
    case unexpectedValue(JSON)
}

public protocol JSONListConvertible {
    init(jsonList: [JSON], context: [CodingUserInfoKey: Any]?) throws
}
