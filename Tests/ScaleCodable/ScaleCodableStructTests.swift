import Foundation
import Testing
import SubstrateScaleCodable

@ScaleCodable
private struct Transfer: Equatable {
    let nonce: UInt32
    let memo: String
}

@ScaleCodable
private struct Empty: Equatable {}

struct ScaleCodableStructTests {
    @Test func encodesFieldsInDeclarationOrder() throws {
        let value = Transfer(nonce: 1, memo: "hi")

        #expect(try value.scaleEncoded() == Data([0x01, 0x00, 0x00, 0x00, 0x08, 0x68, 0x69]))
    }

    @Test func roundTripsStruct() throws {
        let value = Transfer(nonce: 0xDEADBEEF, memo: "memo")

        let decoded = try Transfer(scaleDecoder: ScaleDecoder(data: value.scaleEncoded()))

        #expect(decoded == value)
    }

    @Test func emptyStructEncodesToNoBytes() throws {
        #expect(try Empty().scaleEncoded().isEmpty)
        #expect(try Empty(scaleDecoder: ScaleDecoder(data: Data())) == Empty())
    }
}
