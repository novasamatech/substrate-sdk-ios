#if canImport(SubstrateScaleMacrosPlugin)
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct EnumExpansionTests {
    @Test func expandsPayloadEnum() {
        assertScaleExpansion(
            """
            @ScaleCodable
            enum Content {
                @ScaleCase(0) case text(String)
                @ScaleCase(3) case added
                @ScaleCase(7) case reaction(messageId: String, emoji: String)
            }
            """,
            expandedSource: """
            enum Content {
                case text(String)
                case added
                case reaction(messageId: String, emoji: String)
            }

            extension Content: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    switch self {
                    case let .text(p0):
                        try UInt8(0).encode(scaleEncoder: scaleEncoder)
                        try SubstrateScaleCodable.ScaleField.encode(p0, to: scaleEncoder)
                    case .added:
                        try UInt8(3).encode(scaleEncoder: scaleEncoder)
                    case let .reaction(p0, p1):
                        try UInt8(7).encode(scaleEncoder: scaleEncoder)
                        try SubstrateScaleCodable.ScaleField.encode(p0, to: scaleEncoder)
                        try SubstrateScaleCodable.ScaleField.encode(p1, to: scaleEncoder)
                    }
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    switch try UInt8(scaleDecoder: scaleDecoder) {
                    case 0:
                        let p0: String = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                        self = .text(p0)
                    case 3:
                        self = .added
                    case 7:
                        let p0: String = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                        let p1: String = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                        self = .reaction(messageId: p0, emoji: p1)
                    default:
                        throw SubstrateSdk.ScaleCodingError.unexpectedDecodedValue
                    }
                }
            }
            """
        )
    }

    @Test func expandsRawValueEnum() {
        assertScaleExpansion(
            """
            @ScaleCodable
            enum Purpose: UInt8 {
                case audio = 0
                case video = 1
            }
            """,
            expandedSource: """
            enum Purpose: UInt8 {
                case audio = 0
                case video = 1
            }

            extension Purpose: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try self.rawValue.encode(scaleEncoder: scaleEncoder)
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    guard let value = Self(rawValue: try UInt8(scaleDecoder: scaleDecoder)) else {
                        throw SubstrateSdk.ScaleCodingError.unexpectedDecodedValue
                    }
                    self = value
                }
            }
            """
        )
    }

    @Test func rejectsMixedExplicitAndImplicitIndices() {
        assertScaleExpansion(
            """
            @ScaleCodable
            enum Mixed {
                @ScaleCase(1) case a
                case b
            }
            """,
            expandedSource: """
            enum Mixed {
                case a
                case b
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Either all cases or none must have @ScaleCase", line: 4, column: 5)
            ]
        )
    }

    @Test func rejectsDuplicateIndex() {
        assertScaleExpansion(
            """
            @ScaleCodable
            enum Duplicate {
                @ScaleCase(7) case reply
                @ScaleCase(7) case edited
            }
            """,
            expandedSource: """
            enum Duplicate {
                case reply
                case edited
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Duplicate SCALE variant index 7 (also used by 'reply')", line: 4, column: 5)
            ]
        )
    }

    @Test func rejectsScaleCaseOnRawValueEnum() {
        assertScaleExpansion(
            """
            @ScaleCodable
            enum Purpose: UInt8 {
                @ScaleCase(3) case audio = 0
            }
            """,
            expandedSource: """
            enum Purpose: UInt8 {
                case audio = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ScaleCase is not allowed on raw-value enums; the raw value is the index", line: 3, column: 5)
            ]
        )
    }

    @Test func rejectsNonUInt8RawValueEnum() {
        assertScaleExpansion(
            """
            @ScaleCodable
            enum Kind: String {
                case a
            }
            """,
            expandedSource: """
            enum Kind: String {
                case a
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Raw-value enums must use UInt8 raw values", line: 2, column: 12)
            ]
        )
    }
}
#endif
