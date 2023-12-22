import Foundation

public enum RuntimeMetadataSearchEngine {
    public static func findPortableType(
        for type: String,
        in metadata: RuntimeMetadataV14,
        mode: RuntimeTypeMatchingMode
    ) -> PortableType? {
        switch mode {
        case .full:
            let path = RuntimeType.pathFromName(type)
            return metadata.types.types.first(where: { $0.type.path == path })
        case .lastComponent:
            let component = RuntimeType.pathFromName(type).last

            return metadata.types.types.first(where: { $0.type.path.last == component })
        case .firstLastComponents:
            let path = RuntimeType.pathFromName(type)
            let first = path.first
            let last = path.last

            return metadata.types.types.first(
                where: { $0.type.path.first == first && $0.type.path.last == last }
            )
        }
    }

    public static func findParameterType(
        for mainType: String,
        parameterName: String,
        in metadata: RuntimeMetadataV14,
        mode: RuntimeTypeMatchingMode
    ) -> String? {
        guard let type = findPortableType(for: mainType, in: metadata, mode: mode) else {
            return nil
        }

        let lookUpId = type.type.parameters.first(where: { $0.name == parameterName })?.type

        guard let concreteType = metadata.types.types.first(where: { $0.identifier == lookUpId }) else {
            return nil
        }

        return concreteType.type.pathBasedName
    }

    public static func find(type: String, in metadata: RuntimeMetadataV14, mode: RuntimeTypeMatchingMode) -> String? {
        findPortableType(for: type, in: metadata, mode: mode)?.type.pathBasedName
    }
}
