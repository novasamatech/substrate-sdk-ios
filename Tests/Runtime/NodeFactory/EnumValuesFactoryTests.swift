import XCTest
import SubstrateSdk

class EnumValuesFactoryTests: XCTestCase {
    func testValidEnumValues() throws {
        // given

        let typeName = "Payment"
        let expectedValues = ["weight", "class", "paysFee"]

        let json = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"value_list\":[\"weight\",\"class\",\"paysFee\"]}}}"

        let data = json.data(using: .utf8)!

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        guard let enumNode = registry.node(for: typeName) as? EnumValuesNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(enumNode.typeName, typeName)

        XCTAssertEqual(expectedValues, enumNode.values)
    }

    func testInvalidEnumValuesResultsIntoGenericNode() throws {
        let json1 = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"vale_list\":[\"weight\",\"class\",\"paysFee\"]}}}"

        let json2 = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"value_list\": 2}}}"

        let json3 = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"value_list\":[2, 3]}}}"

        let type = "Payment"

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
