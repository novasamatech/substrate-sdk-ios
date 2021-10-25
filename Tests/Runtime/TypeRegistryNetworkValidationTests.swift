import XCTest
import SubstrateSdk

class TypeRegistryNetworkValidationTests: XCTestCase {
    func testTypeRegistryBuildSuccess() throws {
        do {
            let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                                runtimeMetadataName: "westend-metadata")

            XCTAssertTrue(!registry.registeredTypes.isEmpty)
            XCTAssertTrue(registry.registeredTypes.allSatisfy( { !($0 is GenericNode) }))

        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
