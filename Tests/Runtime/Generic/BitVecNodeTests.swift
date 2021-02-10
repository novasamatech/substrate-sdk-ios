import XCTest
import FearlessUtils

class BitVecNodeTests: XCTestCase {
    func testEncodingDecoding() throws {
        // given
        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadataName: "westend-metadata")
        let encoder = DynamicScaleEncoder(registry: typeRegistry, version: 45)
        let bits = (0..<10).map { JSON.boolValue($0 % 2 == 0) }
        let expected = JSON.arrayValue(bits)

        // when

        try encoder.append(json: .arrayValue(bits), type: "BitVec")

        let data = try encoder.encode()

        let decoder = try DynamicScaleDecoder(data: data, registry: typeRegistry, version: 45)
        let result = try decoder.read(type: "BitVec")

        // then

        XCTAssertEqual(expected, result)
        XCTAssertEqual(decoder.remained, 0)
    }

    func testShouldDecodeEmptyFromZeroByte() throws {
        let data = try Data(hexString: "0x00")
        try performDecodingTest(data: data, expected: .arrayValue([]))
    }

    func testShouldDecodeSize2bits() throws {
        let data = try Data(hexString: "0x0803")
        let expected = JSON.arrayValue([
            .boolValue(true),
            .boolValue(true)
        ])

        try performDecodingTest(data: data, expected: expected)
    }

    func testShouldDecodeSize3bits() throws {
        let data = try Data(hexString: "0x0c07")
        let expected = JSON.arrayValue([
            .boolValue(true),
            .boolValue(true),
            .boolValue(true)
        ])

        try performDecodingTest(data: data, expected: expected)
    }

    func testShouldDecodeSize2bytes() throws {
        let data = try Data(hexString: "0x28fd02")
        let bits = [true, false, true, true, true, true, true, true, false, true].map { JSON.boolValue($0) }
        let expected = JSON.arrayValue(bits)
        try performDecodingTest(data: data, expected: expected)
    }

    func testShouldEncodeEmptyToZeroByte() throws {
        let data = try Data(hexString: "0x00")
        try performEncodingTest(value: .arrayValue([]), expected: data)
    }

    func testShouldEncodeSize2bits() throws {
        let expected = try Data(hexString: "0x0803")
        let value = JSON.arrayValue([
            .boolValue(true),
            .boolValue(true)
        ])

        try performEncodingTest(value: value, expected: expected)
    }

    func testShouldEncodeSize3bits() throws {
        let expected = try Data(hexString: "0x0c07")
        let value = JSON.arrayValue([
            .boolValue(true),
            .boolValue(true),
            .boolValue(true)
        ])

        try performEncodingTest(value: value, expected: expected)
    }

    func testShouldEncodeSize2bytes() throws {
        let expected = try Data(hexString: "0x28fd02")
        let bits = [true, false, true, true, true, true, true, true, false, true].map { JSON.boolValue($0) }
        let value = JSON.arrayValue(bits)
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

        let result = try decoder.read(type: "BitVec")

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

        try encoder.append(json: value, type: "BitVec")
        let result = try encoder.encode()

        // then

        XCTAssertEqual(expected, result)
    }
}
