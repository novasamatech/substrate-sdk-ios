import Foundation

public protocol NodeResolver: AnyObject {
    func resolve(for key: String) -> Node?
}

public class ProxyNode: Node {
    public let typeName: String

    public init(typeName: String) {
        self.typeName = typeName
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.append(json: value, type: typeName)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        return try decoder.read(type: typeName)
    }
}
