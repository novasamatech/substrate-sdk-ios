import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ScaleMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ScaleCodableMacro.self,
        ScaleMarkerMacro.self
    ]
}
