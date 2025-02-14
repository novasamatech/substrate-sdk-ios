import Foundation
import SubstrateSdk

public enum JSONHelperError: Error {
    case invalidString
}

extension JSON {
    public static func from(string: String) throws -> JSON {
        guard let data = string.data(using: .utf8) else {
            throw JSONHelperError.invalidString
        }

        return try JSONDecoder().decode(JSON.self, from: data)
    }
}
