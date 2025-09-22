import XCTest
@testable import SubstrateSdk
#if canImport(TestHelpers)
import TestHelpers
#endif


class TypeRegistryTests: XCTestCase {
    func testShouldResolveStruct() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "DefunctVoter")

        // then

        XCTAssertTrue(node is StructNode)
    }

    func testShouldResolveEnum() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "SiTypeDef")

        // then

        XCTAssertTrue(node is EnumNode)
    }

    func testShouldResolveEnumValues() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "AllowedSlots")

        // then

        XCTAssertTrue(node is EnumValuesNode)
    }

    func testShouldResolveSet() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "IdentityFields")

        // then

        XCTAssertTrue(node is SetNode)
    }

    func testShouldResolveTuple() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "(AccountId, RewardPoint)")

        // then

        XCTAssertTrue(node is TupleNode)
    }

    func testShouldResolveFixedArray() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "[CompactScoreCompact; 2]")

        // then

        XCTAssertTrue(node is FixedArrayNode)
    }

    func testShouldResolveNull() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "Null")

        // then

        XCTAssertTrue(node is NullNode)
    }

    func testShouldResolveNullAlias() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "()")

        // then

        guard
            let proxy = node as? ProxyNode,
            let nullNode = registry.resolve(for: proxy.typeName) else {
            XCTFail("Expected proxy to null")
            return
        }

        XCTAssertTrue(nullNode is NullNode)
    }

    func testShouldResolveCompact() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "Compact<Perbill>")

        // then

        XCTAssertTrue(node is CompactNode)
    }

    func testShouldResolveVector() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "Vec<H256>")

        // then

        XCTAssertTrue(node is VectorNode)
    }

    func testShouldResolveOption() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "Option<OpenTipFinderTo225>")

        // then

        XCTAssertTrue(node is OptionNode)
    }

    func testCaseInsensitiveResolutionApplied() throws {
        // given

        let typeName = "IdentityFields"
        let subtypeName = "AccountInfo<Index>"
        let recursiveName = "OptionCall"

        let searchingTypeName = "Accountinfo<Index>"

        let json = "{\"types\":{\"\(typeName)\": \"\(subtypeName)\", \"\(recursiveName)\": \"\(recursiveName)\"}}"

        let data = json.data(using: .utf8)!

        // when

        let registry = try TypeRegistry
            .createFromTypesDefinition(data: data, additionalNodes: [])

        // then

        XCTAssertNotNil(registry.node(for: searchingTypeName))
    }

    func testTableResolutionApplied() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "<T::Lookup as StaticLookup>::Source")

        // then

        XCTAssertNotNil(node)
    }

    func testRegexResolutionApplied() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "DefunctVoter<T>")

        // then

        XCTAssertTrue(node is StructNode)
        XCTAssertEqual(node?.typeName, "DefunctVoter")
    }

    func testGenericsFilterResolutionApplied() throws {
        // given

        let registry = try RuntimeHelper.createTypeRegistry(from: "default",
                                                            runtimeMetadataName: "westend-metadata")

        // when

        let node = registry.node(for: "DefunctVoter<<Lookup as StaticLookup>::Source>")

        // then

        XCTAssertTrue(node is StructNode)
        XCTAssertEqual(node?.typeName, "DefunctVoter")
    }
}
