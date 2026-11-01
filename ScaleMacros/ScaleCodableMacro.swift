import SwiftSyntax
import SwiftSyntaxMacros

public struct ScaleCodableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard
            !protocols.isEmpty,
            let model = ScaleParser.parse(declaration, in: context)
        else {
            return []
        }

        return [try ScaleCodeGenerator.extensionDecl(for: model, extending: type)]
    }
}
