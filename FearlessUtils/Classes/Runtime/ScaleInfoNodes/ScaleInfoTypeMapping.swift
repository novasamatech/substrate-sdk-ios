import Foundation

public protocol SiTypeMapping {
    func map(type: RuntimeType, identifier: String) -> Node?
}

public final class OneOfSiTypeMapper: SiTypeMapping {
    let innerMappers: [SiTypeMapping]

    public init(innerMappers: [SiTypeMapping]) {
        self.innerMappers = innerMappers
    }

    public func map(type: RuntimeType, identifier: String) -> Node? {
        for innerMapper in innerMappers {
            if let node = innerMapper.map(type: type, identifier: identifier) {
                return node
            }
        }

        return nil
    }
}

public final class SiClosureTypeMapper: SiTypeMapping {
    let closure: (RuntimeType) -> Node?

    public init(closure: @escaping (RuntimeType) -> Node?) {
        self.closure = closure
    }

    public func map(type: RuntimeType, identifier: String) -> Node? {
        closure(type)
    }
}

public final class SiOptionTypeMapper: SiTypeMapping {
    public init() {}

    public func map(type: RuntimeType, identifier: String) -> Node? {
        guard type.path == ["Option"] else {
            return nil
        }

        guard let parameter = type.parameters.first, let parameterType = parameter.type else {
            return OptionNode(typeName: identifier, underlying: NullNode())
        }

        let node = ProxyNode(typeName: String(parameterType))
        return OptionNode(typeName: identifier, underlying: node)
    }
}

public final class SiSetTypeMapper: SiTypeMapping {
    public init() {}

    public func map(type: RuntimeType, identifier: String) -> Node? {
        guard type.path.last == "BitFlags" else {
            return nil
        }

        guard case .composite(let value) = type.typeDefinition, let type = value.fields.first?.type else {
            return SetNode(typeName: identifier, bitVector: Set(), itemType: NullNode())
        }

        let internalNode = ProxyNode(typeName: String(type))
        return SetNode(typeName: identifier, bitVector: Set(), itemType: internalNode)
    }
}

public final class SiCompositeNoneToAliasMapper: SiTypeMapping {
    public init() {}

    public func map(type: RuntimeType, identifier: String) -> Node? {
        guard
            case .composite(let compositeValue) = type.typeDefinition,
            compositeValue.fields.count == 1,
            let field = compositeValue.fields.first,
            field.name == nil
            else {
            return nil
        }

        return AliasNode(typeName: identifier, underlyingTypeName: String(field.type))
    }
}
