import XCTest
import FearlessUtils

class OptionNodeFactoryTests: XCTestCase {
    func testValidOptionFactory() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName = "AccountInfo"

        let json = "{\"types\":{\"\(typeName)\": \"Option<\(subtypeName)>\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry.createFromTypesDefinition(data: data)

        // then

        guard let node = registry.node(for: typeName) as? OptionNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(typeName, node.typeName)
        XCTAssertEqual(subtypeName, node.underlying.typeName)
        XCTAssertNotNil(registry.node(for: subtypeName))
    }

    func testInvalidOptionFactory() throws {
        let json1 = "{\"types\":{\"IdentityFields\": \"Opton<AccountInfo>\"}}"

        let json2 = "{\"types\":{\"IdentityFields\": \"OptionAccountInfo>\"}}"

        let json3 = "{\"types\":{\"IdentityFields\": \"Vec<AccountInfo>\"}}"

        let type = "IdentityFields"

        for json in [json1, json2, json3] {
            let data = json.data(using: .utf8)!

            let registry = try TypeRegistry.createFromTypesDefinition(data: data)

            guard let vectorNode = registry.node(for: type) else {
                XCTFail("Unexpected empty node")
                return
            }

            XCTAssertFalse(vectorNode is OptionNode)
        }
    }
}
