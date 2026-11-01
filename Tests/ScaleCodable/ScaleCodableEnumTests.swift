import Foundation
import Testing
import SubstrateScaleCodable

@ScaleCodable
private enum MessageContent: Equatable {
    @ScaleCase(0) case text(String)
    @ScaleCase(3) case contactAdded
    @ScaleCase(7) case reaction(messageId: String, emoji: String)
}

@ScaleCodable
private enum Positional: Equatable {
    case first
    case second(UInt8)
}

@ScaleCodable
private enum DataChannelPurpose: UInt8, Equatable {
    case audio = 0
    case video = 5
}

struct ScaleCodableEnumTests {
    @Test func encodesExplicitIndexBeforePayload() throws {
        #expect(try MessageContent.text("hi").scaleEncoded() == Data([0x00, 0x08, 0x68, 0x69]))
        #expect(try MessageContent.contactAdded.scaleEncoded() == Data([0x03]))
        #expect(
            try MessageContent.reaction(messageId: "a", emoji: "b").scaleEncoded()
                == Data([0x07, 0x04, 0x61, 0x04, 0x62])
        )
    }

    @Test(arguments: [
        MessageContent.text("hello"),
        .contactAdded,
        .reaction(messageId: "id", emoji: "👍")
    ])
    fileprivate func roundTripsEnum(_ value: MessageContent) throws {
        #expect(try MessageContent(scaleDecoder: ScaleDecoder(data: value.scaleEncoded())) == value)
    }

    @Test func throwsOnUnknownIndex() {
        #expect(throws: ScaleCodingError.self) {
            try MessageContent(scaleDecoder: ScaleDecoder(data: Data([0x06])))
        }
    }

    @Test func usesDeclarationPositionWithoutAnnotations() throws {
        #expect(try Positional.first.scaleEncoded() == Data([0x00]))
        #expect(try Positional.second(9).scaleEncoded() == Data([0x01, 0x09]))
    }

    @Test func usesRawValueAsIndex() throws {
        #expect(try DataChannelPurpose.video.scaleEncoded() == Data([0x05]))
        #expect(try DataChannelPurpose(scaleDecoder: ScaleDecoder(data: Data([0x05]))) == .video)
        #expect(throws: ScaleCodingError.self) {
            try DataChannelPurpose(scaleDecoder: ScaleDecoder(data: Data([0x01])))
        }
    }
}
