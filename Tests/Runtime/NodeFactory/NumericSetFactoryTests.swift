import XCTest
import FearlessUtils

class NumericSetFactoryTests: XCTestCase {
    func testValidNumericSetFactory() throws {
        // given

        let typeName = "IdentityFields"
        let itemTypeName = "u64"

        let json = "{\"types\":{\"IdentityFields\":{\"type\":\"set\",\"value_type\":\"u64\",\"value_list\":{\"Display\":1,\"Legal\":2,\"Web\":4}}}}"

        let expectedBitVector = [
            SetNode.Item(name: "Display", value: 1),
            SetNode.Item(name: "Legal", value: 2),
            SetNode.Item(name: "Web", value: 4)
        ]

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry.createFromTypesDefinition(data: data)

        // then

        guard let setNode = registry.node(for: typeName) as? SetNode else {
            XCTFail("Unexpected empty node")
            return
        }

        XCTAssertEqual(typeName, setNode.typeName)
        XCTAssertEqual(expectedBitVector, setNode.bitVector.sorted(by: { $0.value < $1.value }))
        XCTAssertEqual(itemTypeName, setNode.itemType.typeName)
    }

    func testInvalidSetValuesResultsIntoGenericNode() throws {
        let json1 = "{\"types\":{\"IdentityFields\":{\"type\":\"se\",\"value_type\":\"u64\",\"value_list\":{\"Display\":1,\"Legal\":2,\"Web\":4}}}}"

        let json2 = "{\"types\":{\"IdentityFields\":{\"type\":\"set\",\"value_typ\":\"u64\",\"value_list\":{\"Display\":1,\"Legal\":2,\"Web\":4}}}}"

        let json3 = "{\"types\":{\"IdentityFields\":{\"type\":\"set\",\"value_type\":\"u64\",\"value_lis\":{\"Display\":1,\"Legal\":2,\"Web\":4}}}}"

        let json4 = "{\"types\":{\"IdentityFields\":{\"type\":\"set\",\"value_type\":\"u64\",\"value_list\":{\"Display\":\"1\",\"Legal\":2,\"Web\":4}}}}"

        let json5 = "{\"types\":{\"IdentityFields\":{\"type\":\"set\",\"value_type\":\"u64\",\"value_list\":[1,2,4]}}}"

        let type = "IdentityFields"

        for json in [json1, json2, json3, json4, json5] {
            let data = json.data(using: .utf8)!

            let registry = try TypeRegistry.createFromTypesDefinition(data: data)

            guard let structNode = registry.node(for: type) else {
                XCTFail("Unexpected empty node")
                return
            }

            XCTAssertTrue(structNode is GenericNode)
        }
    }
}
