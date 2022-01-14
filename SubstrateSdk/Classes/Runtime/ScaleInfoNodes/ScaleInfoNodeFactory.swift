import Foundation

protocol ScaleInfoNodeFactoryProtocol {
    func buildNode(from type: RuntimeType, identifier: String) -> Node
}

final class ScaleInfoNodeFactory: ScaleInfoNodeFactoryProtocol {
    let nameMapper: SiNameMapping?
    let typeMapper: SiTypeMapping?

    init(typeMapper: SiTypeMapping? = nil, nameMapper: SiNameMapping? = nil) {
        self.typeMapper = typeMapper
        self.nameMapper = nameMapper
    }

    func buildNode(from type: RuntimeType, identifier: String) -> Node {
        if let node = typeMapper?.map(type: type, identifier: identifier) {
            return node
        }

        switch type.typeDefinition {
        case .composite(let value):
            return buildCompositeNode(from: value, identifier: identifier)
        case .variant(let value):
            return buildVariantNode(from: value, identifier: identifier)
        case .sequence(let value):
            return buildSequenceNode(from: value, identifier: identifier)
        case .array(let value):
            return buildArrayNode(from: value, identifier: identifier)
        case .tuple(let value):
            return buildTupleNode(from: value, identifier: identifier)
        case .bitsequence(let value):
            return buildBitsequenceNode(from: value, identifier: identifier)
        case .compact(let value):
            return buildCompactNode(from: value, identifier: identifier)
        case .primitive(let value):
            return buildPrimitiveNode(from: value, identifier: identifier)
        }
    }

    private func buildCompositeNode(
        from value: RuntimeTypeComposite,
        identifier: String
    ) -> Node {
        createStructNode(from: value.fields, identifier: identifier)
    }

    private func buildVariantNode(
        from value: RuntimeTypeVariant,
        identifier: String
    ) -> Node {
        let typeMapping: [IndexedNameNode] = value.variants.map { variantItem in
            let node = createVariantItem(
                from: variantItem.fields,
                identifier: variantItem.name
            )

            let mappedName = nameMapper?.map(name: variantItem.name) ?? variantItem.name
            return IndexedNameNode(index: variantItem.index, name: mappedName, node: node)
        }

        return SiVariantNode(typeName: identifier, typeMapping: typeMapping)
    }

    private func buildSequenceNode(
        from value: RuntimeTypeSequence,
        identifier: String
    ) -> Node {
        let underlyingNode = ProxyNode(typeName: String(value.type))
        return VectorNode(typeName: identifier, underlying: underlyingNode)
    }

    private func buildArrayNode(
        from value: RuntimeTypeArray,
        identifier: String
    ) -> Node {
        let elementType = ProxyNode(typeName: String(value.type))
        return FixedArrayNode(typeName: identifier, elementType: elementType, length: UInt64(value.length))
    }

    private func buildTupleNode(
        from value: RuntimeTypeTuple,
        identifier: String
    ) -> Node {
        let innerNodes = value.components.map { ProxyNode(typeName: String($0)) }
        return TupleNode(typeName: identifier, innerNodes: innerNodes)
    }

    private func buildBitsequenceNode(
        from value: RuntimeTypeBitSequence,
        identifier: String
    ) -> Node {
        BitVecNode()
    }

    private func buildCompactNode(
        from value: RuntimeTypeCompact,
        identifier: String
    ) -> Node {
        let underlyingNode = ProxyNode(typeName: String(value.type))
        return CompactNode(typeName: identifier, underlying: underlyingNode)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func buildPrimitiveNode(
        from value: RuntimeTypePrimitive,
        identifier: String
    ) -> Node {
        switch value {
        case .bool:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.bool.rawValue)
        case .char:
            return GenericNode(typeName: identifier)
        case .u8:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.u8.rawValue)
        case .u16:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.u16.rawValue)
        case .u32:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.u32.rawValue)
        case .u64:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.u64.rawValue)
        case .u128:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.u128.rawValue)
        case .u256:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.u256.rawValue)
        case .i8:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.i8.rawValue)
        case .i16:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.i16.rawValue)
        case .i32:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.i32.rawValue)
        case .i64:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.i64.rawValue)
        case .i128:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.i128.rawValue)
        case .i256:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.i256.rawValue)
        case .str:
            return AliasNode(typeName: identifier, underlyingTypeName: PrimitiveType.string.rawValue)
        }
    }

    private func createVariantItem(
        from fields: [RuntimeTypeField],
        identifier: String
    ) -> Node {
        if fields.isEmpty {
            return NullNode()
        } else if fields.count == 1, let field = fields.first, field.name == nil {
            return ProxyNode(typeName: String(field.type))
        } else {
            return createStructNode(from: fields, identifier: identifier)
        }
    }

    private func createStructNode(
        from fields: [RuntimeTypeField],
        identifier: String
    ) -> StructNode {
        let typeMapping: [NameNode] = fields.enumerated().map { indexedField in
            let fieldId = String(indexedField.element.type)
            let node = ProxyNode(typeName: fieldId)
            let originalName = indexedField.element.name ?? String(indexedField.offset)
            let mappedName = nameMapper?.map(name: originalName) ?? originalName
            return NameNode(name: mappedName, node: node)
        }

        return StructNode(typeName: identifier, typeMapping: typeMapping)
    }
}
