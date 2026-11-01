import Foundation

public enum ScaleDecodingDepthError: Error, Equatable {
    case maxDepthExceeded(typeName: String, limit: Int)
}

/// Per-thread, per-type nesting counter for `@ScaleCodable(maxDepth:)` decoders.
/// Decoding is synchronous, so a recursive decode always stays on one thread.
public enum ScaleDecodingDepth {
    private final class Levels {
        var byType: [ObjectIdentifier: Int] = [:]
    }

    private static let key = "SubstrateScaleCodable.ScaleDecodingDepth"

    private static var levels: Levels {
        let threadDictionary = Thread.current.threadDictionary

        if let levels = threadDictionary[key] as? Levels {
            return levels
        }

        let levels = Levels()
        threadDictionary[key] = levels
        return levels
    }

    public static func enter(_ type: Any.Type, limit: Int) throws {
        let levels = levels
        let identifier = ObjectIdentifier(type)
        let level = levels.byType[identifier] ?? 0

        guard level < limit else {
            throw ScaleDecodingDepthError.maxDepthExceeded(typeName: String(describing: type), limit: limit)
        }

        levels.byType[identifier] = level + 1
    }

    public static func leave(_ type: Any.Type) {
        let levels = levels
        let identifier = ObjectIdentifier(type)
        let level = levels.byType[identifier] ?? 0

        levels.byType[identifier] = level > 1 ? level - 1 : nil
    }
}
