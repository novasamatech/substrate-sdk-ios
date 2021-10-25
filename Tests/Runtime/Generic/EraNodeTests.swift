import XCTest
import SubstrateSdk

class EraNodeTests: XCTestCase {
    func testShouldDecodeImmortal() throws {
        let data = try Data(hexString: "0x00")
        try performDecodingTest(data: data, expected: Era.immortal)
    }

    func testShouldDecodeMortal() throws {
        try performMortalDecodingTest(hex: "0x4e9c", period: 32768, phase: 20000)
        try performMortalDecodingTest(hex: "0xc503", period: 64, phase: 60)
        try performMortalDecodingTest(hex: "0x8502", period: 64, phase: 40)
    }

    func testShouldEncodeImmortal() throws {
        let data = try Data(hexString: "0x00")
        try performEncodingTest(value: Era.immortal, expected: data)
    }

    func testShouldEncodeMortal() throws {
        try performMortalEncodingTest(hex: "0x4e9c", period: 32768, phase: 20000)
        try performMortalEncodingTest(hex: "0xc503", period: 64, phase: 60)
        try performMortalEncodingTest(hex: "0x8502", period: 64, phase: 40)
    }

    // MARK: Private

    private func performMortalDecodingTest(hex: String, period: UInt64, phase: UInt64) throws {
        let data = try Data(hexString: hex)
        let expected = Era.mortal(period: period, phase: phase)

        try performDecodingTest(data: data, expected: expected)
    }

    private func performMortalEncodingTest(hex: String, period: UInt64, phase: UInt64) throws {
        let expected = try Data(hexString: hex)
        let value = Era.mortal(period: period, phase: phase)

        try performEncodingTest(value: value, expected: expected)
    }

    private func performDecodingTest(data: Data, expected: Era) throws {
        // given

        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadataName: "westend-metadata")
        let decoder = try DynamicScaleDecoder(data: data, registry: typeRegistry, version: 45)

        // when

        let result: Era = try decoder.read(of: GenericType.era.name)

        // then

        XCTAssertEqual(expected, result)
        XCTAssertEqual(decoder.remained, 0)
    }

    private func performEncodingTest(value: Era, expected: Data) throws {
        // given

        let typeRegistry = try RuntimeHelper
            .createTypeRegistryCatalog(from: "default",
                                       networkName: "westend",
                                       runtimeMetadataName: "westend-metadata")
        let encoder = DynamicScaleEncoder(registry: typeRegistry, version: 45)

        // when

        try encoder.append(value, ofType: GenericType.era.name)
        let result = try encoder.encode()

        // then

        XCTAssertEqual(expected, result)
    }
}
