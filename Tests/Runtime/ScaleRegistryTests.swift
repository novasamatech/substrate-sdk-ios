import XCTest
import SubstrateSdk

class ScaleRegistryTests: XCTestCase {
    func testShouldResolveStruct() throws {
        // given

        let registry = try ScaleInfoHelper.createTypeRegistry(from: "kusama-v14-metadata")

        // when

        // try to extract account data
        guard let aliasNode = registry.node(for: "5", version: 0) as? AliasNode else {
            XCTFail("Expected alias for node")
            return
        }

        let node = registry.node(for: aliasNode.underlyingTypeName, version: 0)

        // then

        XCTAssertTrue(node is StructNode)
    }
}
