import Foundation

public class TypeRegistry {
    public static func createFromTypesDefinition(data: Data) throws -> TypeRegistry {
        let jsonDecoder = JSONDecoder()
        let json = try jsonDecoder.decode(JSON.self, from: data)

        return TypeRegistry()
    }


}
