import Foundation

public class RegexReplaceResolver: TypeResolving {
    let pattern: String
    let replacement: String

    public init(pattern: String, replacement: String) {
        self.pattern = pattern
        self.replacement = replacement
    }

    public func resolve(typeName: String, using availableNames: Set<String>) -> String? {
        let newTypeName = typeName.replacingOccurrences(of: pattern,
                                                        with: replacement,
                                                        options: .regularExpression)

        return availableNames.contains(newTypeName) ? newTypeName : nil
    }
}

public extension RegexReplaceResolver {
    static func noise() -> RegexReplaceResolver {
        let pattern = "(T::)|(<T>)|(<T as Trait>::)|(<T as Trait<I>>::)" +
            "|(<T as Config>::)|(\n)|((?:grandpa|session|slashing|schedule)::)"
        return RegexReplaceResolver(pattern: pattern, replacement: "")
    }

    static func genericsFilter() -> RegexReplaceResolver {
        let pattern = "(<.+>)$"
        return RegexReplaceResolver(pattern: pattern, replacement: "")
    }
}
