#if canImport(SubstrateScaleMacrosPlugin)
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct DepthExpansionTests {
    @Test func guardsDecodingDepth() {
        assertScaleExpansion(
            """
            @ScaleCodable(maxDepth: 64)
            struct Node {
                let value: UInt8
            }
            """,
            expandedSource: """
            struct Node {
                let value: UInt8
            }

            extension Node: SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable {
                func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
                    try SubstrateScaleCodable.ScaleField.encode(self.value, to: scaleEncoder)
                }

                init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
                    try SubstrateScaleCodable.ScaleDecodingDepth.enter(Self.self, limit: 64)
                    defer {
                        SubstrateScaleCodable.ScaleDecodingDepth.leave(Self.self)
                    }
                    self.value = try SubstrateScaleCodable.ScaleField.decode(from: scaleDecoder)
                }
            }
            """
        )
    }

    @Test func rejectsNonPositiveMaxDepth() {
        assertScaleExpansion(
            """
            @ScaleCodable(maxDepth: 0)
            struct Node {}
            """,
            expandedSource: """
            struct Node {}
            """,
            diagnostics: [
                DiagnosticSpec(message: "maxDepth must be positive", line: 1, column: 1)
            ]
        )
    }
}
#endif
