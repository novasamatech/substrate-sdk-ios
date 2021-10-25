import XCTest
import SubstrateSdk

class DataNodeTests: XCTestCase {
    func testShouldDecodeNone() throws {
        let data = try Data(hexString: "0x00")
        let expected = JSON.arrayValue([.unsignedIntValue(0)])

        try performDecodingTest(data: data, expected: expected)
    }

    func testShouldDecodeRaw() throws {
        let data = try Data(hexString: "0x090102030405060708")
        let expected = JSON.arrayValue([.unsignedIntValue(1),
                                        .arrayValue([.stringValue("0x0102030405060708")])])

        try performDecodingTest(data: data, expected: expected)
    }

    func testShouldDecodeHasher() throws {
        let data = try Data(hexString: "0x241234567890123456789012345678901212345678901234567890123456789012")
        let expected = JSON.arrayValue([.unsignedIntValue(4),
                                        .arrayValue([.stringValue("0x1234567890123456789012345678901212345678901234567890123456789012")])])

        try performDecodingTest(data: data, expected: expected)
    }

    func testShouldEncodeNone() throws {
        let expected = try Data(hexString: "0x00")
        let value = JSON.arrayValue([.unsignedIntValue(0)])

        try performEncodingTest(value: value, expected: expected)
    }

    func testShouldEncodeRaw() throws {
        let expected = try Data(hexString: "0x090102030405060708")
        let value = JSON.arrayValue([.unsignedIntValue(1),
                                     .arrayValue([.stringValue("0x0102030405060708")])])

        try performEncodingTest(value: value, expected: expected)
    }

    func testShouldEncodeHasher() throws {
        let expected = try Data(hexString: "0x241234567890123456789012345678901212345678901234567890123456789012")
        let value = JSON.arrayValue([.unsignedIntValue(4),
                                     .arrayValue([.stringValue("0x1234567890123456789012345678901212345678901234567890123456789012")])])

        try performEncodingTest(value: value, expected: expected)
    }

    // MARK: Private

    private func performDecodingTest(data: Data, expected: JSON) throws {
        // given

        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadataName: "westend-metadata")
        let decoder = try DynamicScaleDecoder(data: data, registry: typeRegistry, version: 45)

        // when

        let result = try decoder.read(type: "Data")

        // then

        XCTAssertEqual(expected, result)
        XCTAssertEqual(decoder.remained, 0)
    }

    private func performEncodingTest(value: JSON, expected: Data) throws {
        // given

        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadataName: "westend-metadata")
        let encoder = DynamicScaleEncoder(registry: typeRegistry, version: 45)

        // when

        try encoder.append(json: value, type: "Data")
        let result = try encoder.encode()

        // then

        XCTAssertEqual(expected, result)
    }
}
