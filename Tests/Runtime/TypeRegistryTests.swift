import XCTest
import FearlessUtils

class TypeRegistryTests: XCTestCase {
    func testTypeRegistryBuildSuccess() throws {
        do {
            guard let defaultUrl = Bundle(for: type(of: self)).url(forResource: "default", withExtension: "json") else {
                XCTFail("Can't find default.json")
                return
            }

            let data = try Data(contentsOf: defaultUrl)
            let registry = try TypeRegistry.createFromTypesDefinition(data: data)

            XCTAssertTrue(!registry.registeredTypes.isEmpty)
            XCTAssertTrue(registry.registeredTypes.allSatisfy( { !($0 is GenericNode) }))
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testCaseInsensitiveResolutionApplied() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName = "AccountInfo<Index>"
        let recursiveName = "OptionCall"

        let searchingTypeName = "Accountinfo<Index>"

        let json = "{\"types\":{\"\(typeName)\": \"\(subtypeName)\", \"\(recursiveName)\": \"\(recursiveName)\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry.createFromTypesDefinition(data: data)

        // then

        XCTAssertNotNil(registry.node(for: searchingTypeName))
    }
}
