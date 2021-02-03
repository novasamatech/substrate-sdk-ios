import XCTest
import FearlessUtils

class TupleNodeFactoryTests: XCTestCase {

    func testValidTupleFactory() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName1 = "AccountInfo"
        let subtypeName2 = "AccountIndex<u64>"

        let json = "{\"types\":{\"\(typeName)\": \"(\(subtypeName1), \(subtypeName2))\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry.createFromTypesDefinition(data: data)

        // then

        guard let tupleNode = registry.node(for: typeName) as? TupleNode else {
            XCTFail("Unexpected empty node")
            return
        }

        let subtypes = tupleNode.innerNodes.map { $0.typeName }

        XCTAssertEqual(typeName, tupleNode.typeName)
        XCTAssertEqual(subtypes, [subtypeName1, subtypeName2])
        XCTAssertNotNil(registry.node(for: subtypeName1))
        XCTAssertNotNil(registry.node(for: subtypeName2))
    }

    func testInvalidTupleFactory() throws {
        let json1 = "{\"types\":{\"IdentityFields\": \"(AccountInfo, AccountIndex\"}}"

        let json2 = "{\"types\":{\"IdentityFields\": \"VecAccountInfo>\"}}"

        let json3 = "{\"types\":{\"IdentityFields\": \"(AccountInfo, AccountIndex,)\"}}"

        let type = "IdentityFields"

        for json in [json1, json2, json3] {
            let data = json.data(using: .utf8)!

            let registry = try TypeRegistry.createFromTypesDefinition(data: data)

            guard let node = registry.node(for: type) else {
                XCTFail("Unexpected empty node")
                return
            }

            XCTAssertFalse(node is TupleNode)
        }
    }

}
