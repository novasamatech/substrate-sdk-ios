import XCTest
import SubstrateSdk

class StructNodeFactoryTests: XCTestCase {
    func testValidStruct() throws {
        // given

        let typeName = "Payment"
        let expectedSubtypes = ["Weight", "DispatchClass", "Pays"]
        let expectedFields = ["weight", "class", "paysFee"]

        let json = "{\"types\": {\"Payment\": {\"type\":\"struct\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

        let data = json.data(using: .utf8)!

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        guard let structNode = registry.node(for: typeName) as? StructNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(structNode.typeName, typeName)

        let resultFields = structNode.typeMapping.map { $0.name }
        let resultSubtypes = structNode.typeMapping.map { $0.node.typeName }

        XCTAssertEqual(expectedFields, resultFields)
        XCTAssertEqual(expectedSubtypes, resultSubtypes)
    }

    func testInvalidStructResultsIntoGenericNode() throws {
        let json1 = "{\"types\": {\"Payment\": {\"type\":\"struc\",\"type_mapping\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

        let json2 = "{\"types\": {\"Payment\": {\"type\":\"struct\",\"type_mappin\":[[\"weight\",\"Weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

        let json3 = "{\"types\": {\"Payment\": {\"type\":\"struct\",\"type_mapping\":[[\"weight\"],[\"class\",\"DispatchClass\"],[\"paysFee\",\"Pays\"]]}}}"

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
