import Foundation

public extension TypeRegistry {
    static func createFromTypesDefinition(data: Data,
                                          additionalNodes: [Node]) throws -> TypeRegistry {
        let jsonDecoder = JSONDecoder()
        let json = try jsonDecoder.decode(JSON.self, from: data)

        return try createFromTypesDefinition(json: json,
                                             additionalNodes: additionalNodes)
    }

    static func createFromTypesDefinition(json: JSON,
                                          additionalNodes: [Node]) throws -> TypeRegistry {
        guard let types = json.types else {
            throw TypeRegistryError.unexpectedJson
        }

        let factories: [TypeNodeFactoryProtocol] = [
            StructNodeFactory(parser: TypeMappingParser.structure()),
            EnumNodeFactory(parser: TypeMappingParser.enumeration()),
            EnumValuesNodeFactory(parser: TypeValuesParser.enumeration()),
            NumericSetNodeFactory(parser: TypeSetParser.generic()),
            TupleNodeFactory(parser: ComponentsParser.tuple()),
            FixedArrayNodeFactory(parser: FixedArrayParser.generic()),
            VectorNodeFactory(parser: RegexParser.vector()),
            OptionNodeFactory(parser: RegexParser.option()),
            CompactNodeFactory(parser: RegexParser.compact()),
            AliasNodeFactory(parser: TermParser.generic())
        ]

        let resolvers: [TypeResolving] = [
            CaseInsensitiveResolver(),
            TableResolver.noise(),
            RegexReplaceResolver.noise(),
            RegexReplaceResolver.genericsFilter()
        ]

        return try TypeRegistry(json: types,
                                nodeFactory: OneOfTypeNodeFactory(children: factories),
                                typeResolver: OneOfTypeResolver(children: resolvers),
                                additionalNodes: additionalNodes)
    }
}
