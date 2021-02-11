import XCTest
import FearlessUtils

class GenericEventNodeTests: XCTestCase {
    func testShouldEncodeEvent() throws {
        do {
            let data = try Data(hexString: "0x01000103")
            let expected = JSON.arrayValue([
                .unsignedIntValue(1),
                .unsignedIntValue(0),
                .arrayValue([
                    .boolValue(true),
                    .stringValue("3")
                ])
            ])

            try performDecodingTest(data: data, expected: expected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testShouldDecodeEvent() throws {
        do {
            let expected = try Data(hexString: "0x01000103")
            let value = JSON.arrayValue([
                .unsignedIntValue(1),
                .unsignedIntValue(0),
                .arrayValue([
                    .boolValue(true),
                    .stringValue("3")
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

        let result = try decoder.read(type: "GenericEvent")

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

        try encoder.append(json: value, type: "GenericEvent")
        let result = try encoder.encode()

        // then

        XCTAssertEqual(expected, result)
    }
}
