import XCTest
@testable import SubstrateSdk

class MultiSignerScaleTests: XCTestCase {
    func testEd25519Encoding() throws {
        let pubKey = Data(repeating: 0xAA, count: 32)
        let signer = MultiSigner.ed25519(pubKey)

        let encoder = ScaleEncoder()
        try signer.encode(scaleEncoder: encoder)

        let encoded = encoder.encode()
        XCTAssertEqual(encoded.count, 1 + 32)
        XCTAssertEqual(encoded[0], MultiSigner.ed25519Index)
        XCTAssertEqual(encoded[1...], pubKey)
    }

    func testEd25519Decoding() throws {
        let pubKey = Data(repeating: 0xAA, count: 32)
        let encoded = Data([MultiSigner.ed25519Index]) + pubKey

        let decoder = try ScaleDecoder(data: encoded)
        let signer = try MultiSigner(scaleDecoder: decoder)

        guard case let .ed25519(data) = signer else {
            XCTFail("Expected ed25519 variant")
            return
        }

        XCTAssertEqual(data, pubKey)
        XCTAssertEqual(decoder.remained, 0)
    }

    func testSr25519Encoding() throws {
        let pubKey = Data(repeating: 0xBB, count: 32)
        let signer = MultiSigner.sr25519(pubKey)

        let encoder = ScaleEncoder()
        try signer.encode(scaleEncoder: encoder)

        let encoded = encoder.encode()
        XCTAssertEqual(encoded.count, 1 + 32)
        XCTAssertEqual(encoded[0], MultiSigner.sr25519Index)
        XCTAssertEqual(encoded[1...], pubKey)
    }

    func testSr25519Decoding() throws {
        let pubKey = Data(repeating: 0xBB, count: 32)
        let encoded = Data([MultiSigner.sr25519Index]) + pubKey

        let decoder = try ScaleDecoder(data: encoded)
        let signer = try MultiSigner(scaleDecoder: decoder)

        guard case let .sr25519(data) = signer else {
            XCTFail("Expected sr25519 variant")
            return
        }

        XCTAssertEqual(data, pubKey)
        XCTAssertEqual(decoder.remained, 0)
    }

    func testEcdsaEncoding() throws {
        let pubKey = Data(repeating: 0xCC, count: 33)
        let signer = MultiSigner.ecdsa(pubKey)

        let encoder = ScaleEncoder()
        try signer.encode(scaleEncoder: encoder)

        let encoded = encoder.encode()
        XCTAssertEqual(encoded.count, 1 + 33)
        XCTAssertEqual(encoded[0], MultiSigner.ecdsaIndex)
        XCTAssertEqual(encoded[1...], pubKey)
    }

    func testEcdsaDecoding() throws {
        let pubKey = Data(repeating: 0xCC, count: 33)
        let encoded = Data([MultiSigner.ecdsaIndex]) + pubKey

        let decoder = try ScaleDecoder(data: encoded)
        let signer = try MultiSigner(scaleDecoder: decoder)

        guard case let .ecdsa(data) = signer else {
            XCTFail("Expected ecdsa variant")
            return
        }

        XCTAssertEqual(data, pubKey)
        XCTAssertEqual(decoder.remained, 0)
    }

    func testRoundtrip() throws {
        let variants: [MultiSigner] = [
            .ed25519(Data(repeating: 0x01, count: 32)),
            .sr25519(Data(repeating: 0x02, count: 32)),
            .ecdsa(Data(repeating: 0x03, count: 33))
        ]

        for original in variants {
            let encoder = ScaleEncoder()
            try original.encode(scaleEncoder: encoder)

            let decoder = try ScaleDecoder(data: encoder.encode())
            let decoded = try MultiSigner(scaleDecoder: decoder)

            XCTAssertEqual(decoder.remained, 0)
            XCTAssertEqual(decoded, original)
        }
    }

    func testUnknownIndexThrows() throws {
        let encoded = Data([3]) + Data(repeating: 0x00, count: 32)

        let decoder = try ScaleDecoder(data: encoded)

        XCTAssertThrowsError(try MultiSigner(scaleDecoder: decoder))
    }
}
