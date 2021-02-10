import XCTest
import FearlessUtils

class AliasNodeFactoryTests: XCTestCase {
    func testValidAliasFactory() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName = "AccountInfo<Index>"
        let recursiveName = "OptionCall"

        let json = "{\"types\":{\"\(typeName)\": \"\(subtypeName)\", \"\(recursiveName)\": \"\(recursiveName)\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        // then

        XCTAssertNotNil(registry.node(for: typeName))
        XCTAssertNotNil(registry.node(for: subtypeName))
        XCTAssertNotNil(registry.node(for: recursiveName))
    }

    func testInvalidAliasFactory() throws {
        let json1 = "{\"types\":{\"IdentityFields\": 2}}"

        let json2 = "{\"types\":{\"IdentityFields\": [2, 3]}}"

        let json3 = "{\"types\":{\"IdentityFields\": {\"Type\": \"Value\"}}}"

        let type = "IdentityFields"

        for json in [json1, json2, json3] {
            let data = json.data(using: .utf8)!

            let registry = try TypeRegistry
                .createFromTypesDefinition(data: data, additionalNodes: [])

            guard let node = registry.node(for: type) else {
                XCTFail("Unexpected empty node")
                return
            }

            XCTAssertTrue(node is GenericNode)
        }
    }
}
