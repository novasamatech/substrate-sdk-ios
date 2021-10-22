import XCTest
import FearlessUtils

class ScaleRegistryTests: XCTestCase {
    func testShouldResolveStruct() throws {
        // given

        let registry = try ScaleInfoHelper.createTypeRegistry(from: "kusama-v14-metadata")

        // when

        // try to extract account data
        let node = registry.node(for: "5", version: 0)

        // then

        XCTAssertTrue(node is StructNode)
    }
}
