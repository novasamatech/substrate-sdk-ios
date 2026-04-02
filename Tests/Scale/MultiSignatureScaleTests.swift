import XCTest
@testable import SubstrateSdk

class MultiSignatureScaleTests: XCTestCase {
    func testSr25519Encoding() throws {
        let signatureData = Data(repeating: 0xAA, count: MultiSignature.sr25519Length)
        let signature = MultiSignature.sr25519(data: signatureData)

        let encoder = ScaleEncoder()
        try signature.encode(scaleEncoder: encoder)

        let encoded = encoder.encode()
        XCTAssertEqual(encoded.count, 1 + MultiSignature.sr25519Length)
        XCTAssertEqual(encoded[0], MultiSignature.sr25519Index)
        XCTAssertEqual(encoded[1...], signatureData)
    }

    func testSr25519Decoding() throws {
        let signatureData = Data(repeating: 0xAA, count: MultiSignature.sr25519Length)
        let encoded = Data([MultiSignature.sr25519Index]) + signatureData

        let decoder = try ScaleDecoder(data: encoded)
        let signature = try MultiSignature(scaleDecoder: decoder)

        guard case let .sr25519(data) = signature else {
            XCTFail("Expected sr25519 variant")
            return
        }

        XCTAssertEqual(data, signatureData)
    }

    func testEd25519Encoding() throws {
        let signatureData = Data(repeating: 0xBB, count: MultiSignature.ed25519Length)
        let signature = MultiSignature.ed25519(data: signatureData)

        let encoder = ScaleEncoder()
        try signature.encode(scaleEncoder: encoder)

        let encoded = encoder.encode()
        XCTAssertEqual(encoded.count, 1 + MultiSignature.ed25519Length)
        XCTAssertEqual(encoded[0], MultiSignature.ed25519Index)
        XCTAssertEqual(encoded[1...], signatureData)
    }

    func testEd25519Decoding() throws {
        let signatureData = Data(repeating: 0xBB, count: MultiSignature.ed25519Length)
        let encoded = Data([MultiSignature.ed25519Index]) + signatureData

        let decoder = try ScaleDecoder(data: encoded)
        let signature = try MultiSignature(scaleDecoder: decoder)

        guard case let .ed25519(data) = signature else {
            XCTFail("Expected ed25519 variant")
            return
        }

        XCTAssertEqual(data, signatureData)
    }

    func testEcdsaEncoding() throws {
        let signatureData = Data(repeating: 0xCC, count: MultiSignature.ecdsaLength)
        let signature = MultiSignature.ecdsa(data: signatureData)

        let encoder = ScaleEncoder()
        try signature.encode(scaleEncoder: encoder)

        let encoded = encoder.encode()
        XCTAssertEqual(encoded.count, 1 + MultiSignature.ecdsaLength)
        XCTAssertEqual(encoded[0], MultiSignature.ecdsaIndex)
        XCTAssertEqual(encoded[1...], signatureData)
    }

    func testEcdsaDecoding() throws {
        let signatureData = Data(repeating: 0xCC, count: MultiSignature.ecdsaLength)
        let encoded = Data([MultiSignature.ecdsaIndex]) + signatureData

        let decoder = try ScaleDecoder(data: encoded)
        let signature = try MultiSignature(scaleDecoder: decoder)

        guard case let .ecdsa(data) = signature else {
            XCTFail("Expected ecdsa variant")
            return
        }

        XCTAssertEqual(data, signatureData)
    }

    func testRoundtrip() throws {
        let variants: [MultiSignature] = [
            .sr25519(data: Data(repeating: 0x01, count: MultiSignature.sr25519Length)),
            .ed25519(data: Data(repeating: 0x02, count: MultiSignature.ed25519Length)),
            .ecdsa(data: Data(repeating: 0x03, count: MultiSignature.ecdsaLength))
        ]

        for original in variants {
            let encoder = ScaleEncoder()
            try original.encode(scaleEncoder: encoder)

            let decoder = try ScaleDecoder(data: encoder.encode())
            let decoded = try MultiSignature(scaleDecoder: decoder)

            XCTAssertEqual(decoder.remained, 0)

            switch (original, decoded) {
            case let (.sr25519(lhs), .sr25519(rhs)),
                 let (.ed25519(lhs), .ed25519(rhs)),
                 let (.ecdsa(lhs), .ecdsa(rhs)):
                XCTAssertEqual(lhs, rhs)
            default:
                XCTFail("Variant mismatch")
            }
        }
    }

    func testUnknownIndexThrows() throws {
        let encoded = Data([3]) + Data(repeating: 0x00, count: 64)

        let decoder = try ScaleDecoder(data: encoded)

        XCTAssertThrowsError(try MultiSignature(scaleDecoder: decoder))
    }
}
