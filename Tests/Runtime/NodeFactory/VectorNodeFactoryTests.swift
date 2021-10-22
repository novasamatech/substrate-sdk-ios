import XCTest
import FearlessUtils

class VectorNodeFactoryTests: XCTestCase {
    func testValidVectorFactory() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName = "AccountInfo"

        let json = "{\"types\":{\"\(typeName)\": \"Vec<\(subtypeName)>\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        // then

        guard let vectorNode = registry.node(for: typeName) as? VectorNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(typeName, vectorNode.typeName)
        XCTAssertEqual(subtypeName, vectorNode.underlying.typeName)
        XCTAssertNotNil(registry.node(for: subtypeName))
    }

    func testInvalidVectorFactory() throws {
        let json1 = "{\"types\":{\"IdentityFields\": \"Ve<AccountInfo>\"}}"

        let json2 = "{\"types\":{\"IdentityFields\": \"VecAccountInfo>\"}}"

        let json3 = "{\"types\":{\"IdentityFields\": \"Option<AccountInfo>\"}}"

        let type = "IdentityFields"

        for json in [json1, json2, json3] {
            let data = json.data(using: .utf8)!

            let registry = try TypeRegistry
                .createFromTypesDefinition(data: data, additionalNodes: [])

            guard let vectorNode = registry.node(for: type) else {
                XCTFail("Unexpected empty node")
                return
            }

            XCTAssertFalse(vectorNode is VectorNode)
        }
    }
}
