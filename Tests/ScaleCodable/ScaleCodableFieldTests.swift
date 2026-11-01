import BigInt
import Foundation
import Testing
import SubstrateScaleCodable

private typealias Flag = Bool

@ScaleCodable
private struct Fields: Equatable {
    @ScaleFixed(4) let key: Data
    @ScaleVec let blob: Data
    let label: String?
    let flag: Bool?
    let aliasedFlag: Flag?
    @ScaleCompact let index: UInt32
    @ScaleCompact let parent: UInt32?
    @ScaleFixed(2) let tag: Data?
    @ScaleCompact let ids: [UInt16]
}

@ScaleCodable
private struct Narrow: Equatable {
    @ScaleCompact let value: UInt8
}

@ScaleCodable
private struct Box<Value>: Equatable where Value: Equatable {
    let value: Value
}

@ScaleCodable
private enum Optionals: Equatable {
    case maybe(String?)
    case flag(Bool?)
}

struct ScaleCodableFieldTests {
    private let sample = Fields(
        key: Data([1, 2, 3, 4]),
        blob: Data([0xAA]),
        label: "hi",
        flag: false,
        aliasedFlag: true,
        index: 300,
        parent: nil,
        tag: Data([7, 8]),
        ids: [1, 300]
    )

    @Test func encodesEachMarkerAndOptionalForm() throws {
        let expected = Data([
            0x01, 0x02, 0x03, 0x04, // fixed 4, no prefix
            0x04, 0xAA, // Vec<u8>
            0x01, 0x08, 0x68, 0x69, // Option<String>
            0x02, // Option<bool> false
            0x01, // Option<bool> true through a typealias
            0xB1, 0x04, // compact 300
            0x00, // Option<Compact<u32>> none
            0x01, 0x07, 0x08, // Option<[u8; 2]>
            0x08, 0x04, 0xB1, 0x04 // Vec<Compact<u16>>
        ])

        #expect(try sample.scaleEncoded() == expected)
    }

    @Test func roundTripsAllFieldForms() throws {
        #expect(try Fields(scaleDecoder: ScaleDecoder(data: sample.scaleEncoded())) == sample)

        let empty = Fields(
            key: Data(count: 4), blob: Data(), label: nil, flag: nil, aliasedFlag: nil,
            index: 0, parent: 7, tag: nil, ids: []
        )
        #expect(try Fields(scaleDecoder: ScaleDecoder(data: empty.scaleEncoded())) == empty)
    }

    @Test func encodesNilBoolAsSingleZeroByte() throws {
        #expect(try Optionals.flag(nil).scaleEncoded() == Data([0x01, 0x00]))
        #expect(try Optionals.flag(true).scaleEncoded() == Data([0x01, 0x01]))
        #expect(try Optionals.maybe(nil).scaleEncoded() == Data([0x00, 0x00]))
    }

    @Test func throwsWhenFixedLengthDoesNotMatchOnEncode() {
        var invalid = sample
        invalid = Fields(
            key: Data([1, 2, 3]), blob: invalid.blob, label: nil, flag: nil, aliasedFlag: nil,
            index: 0, parent: nil, tag: nil, ids: []
        )

        #expect(throws: ScaleCodingError.self) {
            try invalid.scaleEncoded()
        }
    }

    @Test func throwsInsteadOfTrappingWhenCompactOverflows() throws {
        let encoded300 = try BigUInt(300).scaleEncoded()

        #expect(throws: ScaleCodingError.self) {
            try Narrow(scaleDecoder: ScaleDecoder(data: encoded300))
        }
    }

    @Test func encodesGenericValue() throws {
        #expect(try Box(value: UInt16(0x0102)).scaleEncoded() == Data([0x02, 0x01]))
        #expect(try Box<String>(scaleDecoder: ScaleDecoder(data: Data([0x04, 0x61]))) == Box(value: "a"))
    }
}
