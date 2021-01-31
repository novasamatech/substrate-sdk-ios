import XCTest
import FearlessUtils

class TypeRegistryTests: XCTestCase {
    func testTypeRegistryCreation() throws {
        do {
            guard let defaultUrl = Bundle(for: type(of: self)).url(forResource: "default", withExtension: "json") else {
                XCTFail("Can't find default.json")
                return
            }

            let data = try Data(contentsOf: defaultUrl)
            let registry = try TypeRegistry.createFromTypesDefinition(data: data)

            let genericTypeNames: [String] = registry.registeredTypes.compactMap { node in
                guard node is SetNode else {
                    return nil
                }

                return node.typeName
            }

            for name in genericTypeNames {
                print(name)
            }

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
