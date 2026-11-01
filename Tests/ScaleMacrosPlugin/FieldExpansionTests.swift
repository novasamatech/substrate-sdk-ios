#if canImport(SubstrateScaleMacrosPlugin)
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct FieldExpansionTests {
    @Test func routesMarkersToHelpers() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Fields {
                @ScaleFixed(32) let key: Data
                @ScaleVec let blob: Data
                @ScaleCompact let index: UInt32
                let label: String?
            }
            """,
            expandedSource: """
            struct Fields {
                let key: Data
                let blob: Data
                let index: UInt32
                let label: String?
            }

            extension Fields: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleFixedBytes.encode(self.key, length: 32, to: scaleEncoder)
                    try SubstrateScaleCodable.ScaleField.encode(self.blob, to: scaleEncoder)
                    try SubstrateScaleCodable.ScaleCompact.encode(self.index, to: scaleEncoder)
                    try SubstrateScaleCodable.ScaleField.encode(self.label, to: scaleEncoder)
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    self.key = try SubstrateScaleCodable.ScaleFixedBytes.decode(length: 32, from: scaleDecoder)
                    self.blob = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                    self.index = try SubstrateScaleCodable.ScaleCompact.decode(from: scaleDecoder)
                    self.label = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """
        )
    }

    @Test func warnsOnAmbiguousByteTokenWithFixIts() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Request {
                let acceptorId: AccountId
            }
            """,
            expandedSource: """
            struct Request {
                let acceptorId: AccountId
            }

            extension Request: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleField.encode(self.acceptorId, to: scaleEncoder)
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    self.acceptorId = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'AccountId' encodes as length-prefixed Vec<u8>; mark it @ScaleVec or @ScaleFixed(n)",
                    line: 3,
                    column: 5,
                    severity: .warning,
                    fixIts: [
                        FixItSpec(message: "Add @ScaleVec (length-prefixed)"),
                        FixItSpec(message: "Add @ScaleFixed(32) (raw bytes)")
                    ]
                )
            ]
        )
    }

    @Test func fixItInsertsMarkerBeforeProperty() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Request {
                let payload: Data?
            }
            """,
            expandedSource: """
            struct Request {
                let payload: Data?
            }

            extension Request: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleField.encode(self.payload, to: scaleEncoder)
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    self.payload = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "'Data' encodes as length-prefixed Vec<u8>; mark it @ScaleVec or @ScaleFixed(n)",
                    line: 3,
                    column: 5,
                    severity: .warning,
                    fixIts: [
                        FixItSpec(message: "Add @ScaleVec (length-prefixed)"),
                        FixItSpec(message: "Add @ScaleFixed(32) (raw bytes)")
                    ]
                )
            ],
            applyFixIts: ["Add @ScaleVec (length-prefixed)"],
            fixedSource: """
            @ScaleCodable
            struct Request {
                @ScaleVec let payload: Data?
            }
            """
        )
    }

    @Test func rejectsConflictingMarkers() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Conflict {
                @ScaleFixed(4) @ScaleCompact let value: Data
            }
            """,
            expandedSource: """
            struct Conflict {
                let value: Data
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Use only one of @ScaleFixed, @ScaleVec, @ScaleCompact", line: 3, column: 5)
            ]
        )
    }

    @Test func rejectsNonPositiveFixedLength() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Zero {
                @ScaleFixed(0) let value: Data
            }
            """,
            expandedSource: """
            struct Zero {
                let value: Data
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ScaleFixed length must be positive", line: 3, column: 5)
            ]
        )
    }

    @Test func rejectsNestedOptional() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Nested {
                let value: String??
            }
            """,
            expandedSource: """
            struct Nested {
                let value: String??
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Nested optionals are not supported", line: 3, column: 16)
            ]
        )
    }

    @Test func constrainsGenericParameters() {
        assertScaleExpansion(
            """
            @ScaleCodable
            public struct Component<Props> {
                public let props: Props
            }
            """,
            expandedSource: """
            public struct Component<Props> {
                public let props: Props
            }

            extension Component: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable where Props: SubstrateSdk.ScaleEncodable & SubstrateSdk.ScaleDecodable {
                public func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleField.encode(self.props, to: scaleEncoder)
                }

                public init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    self.props = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """
        )
    }
}
#endif
