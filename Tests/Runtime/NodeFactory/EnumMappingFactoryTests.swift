import XCTest
import SubstrateSdk

class EnumMappingFactoryTests: XCTestCase {

    func testValidEnum() throws {
        // given

        let typeName = "Payment"
        let expectedSubtypes = ["Weight", "DispatchClass", "Pays"]
        let expectedFields = ["weight", "class", "paysFee"]

        let json = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

        let data = json.data(using: .utf8)!

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        guard let enumNode = registry.node(for: typeName) as? EnumNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(enumNode.typeName, typeName)

        let resultFields = enumNode.typeMapping.map { $0.name }
        let resultSubtypes = enumNode.typeMapping.map { $0.node.typeName }

        XCTAssertEqual(expectedFields, resultFields)
        XCTAssertEqual(expectedSubtypes, resultSubtypes)
    }

    func testInvalidEnumResultsIntoGenericNode() throws {
        let json1 = "{\"types\": {\"Payment\": {\"type\":\"enu\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

        let json2 = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"type_mappin\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

        let json3 = "{\"types\": {\"Payment\": {\"type\":\"enum\",\"type_mapping\":[[\"weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

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
