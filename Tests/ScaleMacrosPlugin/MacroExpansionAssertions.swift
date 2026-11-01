// Macro plugins are host-only: run via the macOS `ScaleMacrosPluginTests` scheme.
#if canImport(SubstrateScaleMacrosPlugin)
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing
import SubstrateScaleMacrosPlugin

let scaleMacroSpecs: [String: MacroSpec] = [
    "ScaleCodable": MacroSpec(
        type: ScaleCodableMacro.self,
        conformances: ["ScaleEncodable", "ScaleDecodable"]
    ),
    "ScaleCase": MacroSpec(type: ScaleMarkerMacro.self),
    "ScaleFixed": MacroSpec(type: ScaleMarkerMacro.self),
    "ScaleVec": MacroSpec(type: ScaleMarkerMacro.self),
    "ScaleCompact": MacroSpec(type: ScaleMarkerMacro.self)
]

func assertScaleExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    applyFixIts: [String]? = nil,
    fixedSource: String? = nil,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    assertMacroExpansion(
        originalSource,
        expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: scaleMacroSpecs,
        applyFixIts: applyFixIts,
        fixedSource: fixedSource,
        indentationWidth: .spaces(4),
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: SourceLocation(
                    fileID: String(describing: failure.location.fileID),
                    filePath: String(describing: failure.location.filePath),
                    line: Int(failure.location.line),
                    column: Int(failure.location.column)
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}
#endif
