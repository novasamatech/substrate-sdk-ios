import XCTest
@testable import SubstrateSdk
#if canImport(TestHelpers)
import TestHelpers
#endif


class GenericCallNodeTests: XCTestCase {

    func testShouldDecodeCall() throws {
        do {
            let data = try Data(hexString: "0x01000103")
            let expected = JSON.dictionaryValue([
                "moduleName": .stringValue("A"),
                "callName": .stringValue("B"),
                "args": .dictionaryValue([
                    "arg1": .boolValue(true),
                    "arg2": .stringValue("3")
                ])
            ])

            try performDecodingTest(data: data, expected: expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testShouldEncodeCall() throws {
        do {
            let expected = try Data(hexString: "0x01000103")
            let value = JSON.dictionaryValue([
                "moduleName": .stringValue("A"),
                "callName": .stringValue("B"),
                "args": .dictionaryValue([
                    "arg1": .boolValue(true),
                    "arg2": .stringValue("3")
                ])
            ])

            try performEncodingTest(value: value, expected: expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: Private

    private func performDecodingTest(data: Data, expected: JSON) throws {
        // given

        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadata: RuntimeHelper.dummyRuntimeMetadata)
        let decoder = try DynamicScaleDecoder(data: data, registry: typeRegistry, version: 45)

        // when

        let result = try decoder.read(type: "GenericCall")

        // then

        XCTAssertEqual(expected, result)
        XCTAssertEqual(decoder.remained, 0)
    }

    private func performEncodingTest(value: JSON, expected: Data) throws {
        // given

        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadata: RuntimeHelper.dummyRuntimeMetadata)
        let encoder = DynamicScaleEncoder(registry: typeRegistry, version: 45)

        // when

        try encoder.append(json: value, type: "GenericCall")
        let result = try encoder.encode()

        // then

        XCTAssertEqual(expected, result)
    }
}
