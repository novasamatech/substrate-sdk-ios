import SwiftSyntax
import SwiftSyntaxMacros

/// Marker attributes expand to nothing; `ScaleCodableMacro` reads them from the syntax tree.
public struct ScaleMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
