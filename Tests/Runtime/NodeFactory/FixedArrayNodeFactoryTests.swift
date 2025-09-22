import XCTest
@testable import SubstrateSdk

class FixedArrayNodeFactoryTests: XCTestCase {
    func testValidFixedArrayFactory() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName = "AccountInfo"
        let length: UInt64 = 32

        let json = "{\"types\":{\"\(typeName)\": \"[\(subtypeName); \(length)]\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        // then

        guard let node = registry.node(for: typeName) as? FixedArrayNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(typeName, node.typeName)
        XCTAssertEqual(subtypeName, node.elementType.typeName)
        XCTAssertEqual(length, node.length)
        XCTAssertNotNil(registry.node(for: subtypeName))
    }

    func testInvalidFixedArrayFactory() throws {
        let json1 = "{\"types\":{\"IdentityFields\": \"[AccountInfo; 32\"}}"

        let json2 = "{\"types\":{\"IdentityFields\": \"VecAccountInfo>\"}}"

        let json3 = "{\"types\":{\"IdentityFields\": \"(AccountInfo, 32)\"}}"

        let type = "IdentityFields"

        for json in [json1, json2, json3] {
            let data = json.data(using: .utf8)!

            let registry = try TypeRegistry
                .createFromTypesDefinition(data: data, additionalNodes: [])

            guard let node = registry.node(for: type) else {
                XCTFail("Unexpected empty node")
                return
            }

            XCTAssertFalse(node is FixedArrayNode)
        }
    }
}
