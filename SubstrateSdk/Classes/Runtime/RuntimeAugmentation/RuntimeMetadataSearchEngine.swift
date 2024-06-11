import Foundation

public enum RuntimeMetadataSearchEngine {
    public static func findPortableTypes(
        for type: String,
        in metadata: PostV14RuntimeMetadataProtocol,
        mode: RuntimeTypeMatchingMode
    ) -> [PortableType] {
        switch mode {
        case .full:
            let path = RuntimeType.pathFromName(type)
            return metadata.types.types.filter({ $0.type.path == path })
        case .lastComponent:
            let component = RuntimeType.pathFromName(type).last

            return metadata.types.types.filter({ $0.type.path.last == component })
        case .firstLastComponents:
            let path = RuntimeType.pathFromName(type)
            let first = path.first
            let last = path.last

            return metadata.types.types.filter { $0.type.path.first == first && $0.type.path.last == last }
        }
    }

    public static func findParameterType(
        for mainType: String,
        parameterName: String,
        in metadata: PostV14RuntimeMetadataProtocol,
        mode: RuntimeTypeMatchingMode
    ) -> String? {
        guard let type = findPortableTypes(for: mainType, in: metadata, mode: mode).first else {
            return nil
        }

        let lookUpId = type.type.parameters.first(where: { $0.name == parameterName })?.type

        guard let concreteType = metadata.types.types.first(where: { $0.identifier == lookUpId }) else {
            return nil
        }

        return String(concreteType.identifier)
    }

    public static func find(
        type: String,
        in metadata: PostV14RuntimeMetadataProtocol,
        mode: RuntimeTypeMatchingMode
    ) -> String? {
        let types = findPortableTypes(for: type, in: metadata, mode: mode)

        guard let concreteType = types.first else {
            return nil
        }

        if types.count > 1 {
            return concreteType.type.pathBasedName ?? String(concreteType.identifier)
        } else {
            return String(concreteType.identifier)
        }
    }
}
