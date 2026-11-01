#if canImport(SubstrateScaleMacrosPlugin)
import SwiftSyntaxMacrosGenericTestSupport
import SubstrateScaleMacrosPlugin
import Testing

struct StructExpansionTests {
    @Test func expandsStoredPropertiesInOrder() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Transfer {
                let nonce: UInt32
                var memo: String
                static let version: UInt8 = 1
                let kind = 0
                var computed: Int { 1 }
            }
            """,
            expandedSource: """
            struct Transfer {
                let nonce: UInt32
                var memo: String
                static let version: UInt8 = 1
                let kind = 0
                var computed: Int { 1 }
            }

            extension Transfer: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleField.encode(self.nonce, to: scaleEncoder)
                    try SubstrateScaleCodable.ScaleField.encode(self.memo, to: scaleEncoder)
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    self.nonce = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                    self.memo = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """
        )
    }

    @Test func copiesPublicAccessToWitnesses() {
        assertScaleExpansion(
            """
            @ScaleCodable
            public struct Id {
                public let value: UInt8
            }
            """,
            expandedSource: """
            public struct Id {
                public let value: UInt8
            }

            extension Id: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                public func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleField.encode(self.value, to: scaleEncoder)
                }

                public init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    self.value = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """
        )
    }

    @Test func rejectsClass() {
        assertScaleExpansion(
            """
            @ScaleCodable
            final class Session {}
            """,
            expandedSource: """
            final class Session {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ScaleCodable supports only structs and enums", line: 1, column: 1)
            ]
        )
    }

    @Test func requiresTypeAnnotation() {
        assertScaleExpansion(
            """
            @ScaleCodable
            struct Counter {
                var value = 0
            }
            """,
            expandedSource: """
            struct Counter {
                var value = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Explicit type annotation required", line: 3, column: 9)
            ]
        )
    }

    @Test func skipsWhenConformanceAlreadyDeclared() {
        assertMacroExpansion(
            """
            @ScaleCodable
            struct Manual {}
            """,
            expandedSource: """
            struct Manual {}
            """,
            macroSpecs: ["ScaleCodable": .init(type: ScaleCodableMacro.self, conformances: [])],
            failureHandler: { Issue.record(Comment(rawValue: $0.message)) }
        )
    }
}
#endif
