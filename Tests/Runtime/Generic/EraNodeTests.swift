import XCTest
import FearlessUtils

class EraNodeTests: XCTestCase {
    func testShouldDecodeImmortal() throws {
        let data = try Data(hexString: "0x00")
        try performDecodingTest(data: data, expected: .arrayValue([.unsignedIntValue(0)]))
    }

    func testShouldDecodeMortal() throws {
        try performMortalDecodingTest(hex: "0x4e9c", period: 32768, phase: 20000)
        try performMortalDecodingTest(hex: "0xc503", period: 64, phase: 60)
        try performMortalDecodingTest(hex: "0x8502", period: 64, phase: 40)
    }

    func testShouldEncodeImmortal() throws {
        let data = try Data(hexString: "0x00")
        try performEncodingTest(value: .arrayValue([.unsignedIntValue(0)]), expected: data)
    }

    func testShouldEncodeMortal() throws {
        try performMortalEncodingTest(hex: "0x4e9c", period: 32768, phase: 20000)
        try performMortalEncodingTest(hex: "0xc503", period: 64, phase: 60)
        try performMortalEncodingTest(hex: "0x8502", period: 64, phase: 40)
    }

    // MARK: Private

    private func performMortalDecodingTest(hex: String, period: UInt64, phase: UInt64) throws {
        let data = try Data(hexString: hex)
        let expected = JSON.arrayValue([
            .unsignedIntValue(1),
            .arrayValue([.unsignedIntValue(period), .unsignedIntValue(phase)])
        ])

        try performDecodingTest(data: data, expected: expected)
    }

    private func performMortalEncodingTest(hex: String, period: UInt64, phase: UInt64) throws {
        let expected = try Data(hexString: hex)
        let value = JSON.arrayValue([
            .unsignedIntValue(1),
            .arrayValue([.unsignedIntValue(period), .unsignedIntValue(phase)])
        ])

        try performEncodingTest(value: value, expected: expected)
    }

    private func performDecodingTest(data: Data, expected: JSON) throws {
        // given

        let typeRegistry = try RuntimeHelper.createTypeRegistryCatalog(from: "default", networkName: "westend")
        let decoder = try DynamicScaleDecoder(data: data, registry: typeRegistry, version: 45)

        // when

        let result = try decoder.read(type: "Era")

        // then

        XCTAssertEqual(expected, result)
        XCTAssertEqual(decoder.remained, 0)
    }

    private func performEncodingTest(value: JSON, expected: Data) throws {
        // given

        let typeRegistry = try RuntimeHelper.createTypeRegistryCatalog(from: "default", networkName: "westend")
        let encoder = DynamicScaleEncoder(registry: typeRegistry, version: 45)

        // when

        try encoder.append(json: value, type: "Era")
        let result = try encoder.encode()

        // then

        XCTAssertEqual(expected, result)
    }
}
