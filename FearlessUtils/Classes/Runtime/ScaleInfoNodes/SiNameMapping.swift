import Foundation

public protocol SiNameMapping {
    func map(name: String) -> String
}

public final class ScaleInfoCamelCaseMapper: SiNameMapping {
    public init() {}

    public func map(name: String) -> String {
        let components = name.split(separator: "_")

        guard components.count > 1, let firstComponent = components.first else {
            return name
        }

        let otherComponents = components.suffix(from: 1).map { $0.capitalized }

        return ([String(firstComponent)] + otherComponents).joined()
    }
}
