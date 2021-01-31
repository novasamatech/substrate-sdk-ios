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
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
