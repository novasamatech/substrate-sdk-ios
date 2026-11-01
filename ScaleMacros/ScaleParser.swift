import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum ScaleParser {
    /// Returns nil when the declaration is invalid; diagnostics are already emitted.
    static func parse(
        _ declaration: some DeclGroupSyntax,
        attribute: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> ScaleTypeModel? {
        let accessModifier = accessModifier(of: declaration.modifiers)
        let genericParameters = declaration.genericParameterNames

        guard let maxDepth = parseMaxDepth(of: attribute, in: context) else {
            return nil
        }

        if let structDecl = declaration.as(StructDeclSyntax.self) {
            guard let fields = parseFields(of: structDecl, in: context) else {
                return nil
            }

            return ScaleTypeModel(
                accessModifier: accessModifier,
                genericParameters: genericParameters,
                maxDepth: maxDepth.value,
                kind: .structure(fields)
            )
        }

        if let enumDecl = declaration.as(EnumDeclSyntax.self) {
            return parseEnum(enumDecl, in: context).map {
                ScaleTypeModel(
                    accessModifier: accessModifier,
                    genericParameters: genericParameters,
                    maxDepth: maxDepth.value,
                    kind: $0
                )
            }
        }

        context.diagnose(Diagnostic(node: declaration, message: ScaleDiagnostic.unsupportedDeclaration))
        return nil
    }

    private struct MaxDepth {
        let value: String?
    }

    /// Returns nil when the argument is invalid; diagnostics are already emitted.
    private static func parseMaxDepth(
        of attribute: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> MaxDepth? {
        guard
            case let .argumentList(arguments) = attribute.arguments,
            let argument = arguments.first(where: { $0.label?.text == "maxDepth" })
        else {
            return MaxDepth(value: nil)
        }

        if let literal = argument.expression.as(IntegerLiteralExprSyntax.self),
           let limit = Int(literal.literal.text.filter { $0 != "_" }),
           limit <= 0 {
            context.diagnose(Diagnostic(node: attribute, message: ScaleDiagnostic.nonPositiveMaxDepth))
            return nil
        }

        return MaxDepth(value: argument.expression.trimmedDescription)
    }

    private static let rawValueTypes: Set<String> = [
        "String", "Character", "Int", "Int8", "Int16", "Int32", "Int64",
        "UInt", "UInt16", "UInt32", "UInt64", "Float", "Double"
    ]

    private static func parseEnum(
        _ enumDecl: EnumDeclSyntax,
        in context: some MacroExpansionContext
    ) -> ScaleTypeModel.Kind? {
        let caseDecls = enumDecl.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }

        // only the first inherited type can be a raw type
        if let rawType = enumDecl.inheritanceClause?.inheritedTypes.first?.type {
            let rawTypeName = rawType.trimmedDescription

            if rawTypeName == "UInt8" {
                return parseRawValueEnum(caseDecls, in: context)
            }

            if rawValueTypes.contains(rawTypeName) {
                context.diagnose(Diagnostic(node: rawType, message: ScaleDiagnostic.unsupportedRawType))
                return nil
            }
        }

        return parsePayloadEnum(caseDecls, in: context)
    }

    private static func parseRawValueEnum(
        _ caseDecls: [EnumCaseDeclSyntax],
        in context: some MacroExpansionContext
    ) -> ScaleTypeModel.Kind? {
        let annotated = caseDecls.compactMap(\.scaleCaseAttribute)

        for attribute in annotated {
            context.diagnose(Diagnostic(node: attribute, message: ScaleDiagnostic.scaleCaseOnRawValueEnum))
        }

        return annotated.isEmpty ? .rawValueEnum : nil
    }

    private static func parsePayloadEnum(
        _ caseDecls: [EnumCaseDeclSyntax],
        in context: some MacroExpansionContext
    ) -> ScaleTypeModel.Kind? {
        let hasExplicitIndices = caseDecls.contains { $0.scaleCaseAttribute != nil }
        var cases: [ScaleCaseModel] = []
        var caseNameByIndex: [Int: String] = [:]
        var isValid = true

        for caseDecl in caseDecls {
            let index: Int

            if hasExplicitIndices {
                guard let attribute = caseDecl.scaleCaseAttribute else {
                    context.diagnose(Diagnostic(node: caseDecl, message: ScaleDiagnostic.mixedCaseIndices))
                    isValid = false
                    continue
                }

                guard caseDecl.elements.count == 1 else {
                    context.diagnose(Diagnostic(node: attribute, message: ScaleDiagnostic.scaleCaseOnMultipleElements))
                    isValid = false
                    continue
                }

                // the macro signature already restricts the literal to UInt8
                guard let literal = attribute.integerLiteralArgument else {
                    context.diagnose(Diagnostic(node: attribute, message: ScaleDiagnostic.nonLiteralIndex))
                    isValid = false
                    continue
                }

                index = literal
            } else {
                index = cases.count
            }

            for (offset, element) in caseDecl.elements.enumerated() {
                let elementIndex = index + offset
                let name = element.name.text

                if let existingCase = caseNameByIndex[elementIndex] {
                    context.diagnose(
                        Diagnostic(
                            node: caseDecl,
                            message: ScaleDiagnostic.duplicateIndex(elementIndex, existingCase: existingCase)
                        )
                    )
                    isValid = false
                    continue
                }

                caseNameByIndex[elementIndex] = name

                let parameters = element.parameterClause?.parameters ?? []

                guard parameters.allSatisfy({ validateNotNestedOptional($0.type, in: context) }) else {
                    isValid = false
                    continue
                }

                let payload: [ScalePayloadModel] = parameters.map { parameter in
                    let label = parameter.firstName.flatMap { $0.tokenKind == .wildcard ? nil : $0.text }
                    return ScalePayloadModel(label: label, type: parameter.type.trimmed)
                }

                cases.append(ScaleCaseModel(name: name, index: elementIndex, payload: payload))
            }
        }

        if !hasExplicitIndices, cases.count > 256, let lastCase = caseDecls.last {
            context.diagnose(Diagnostic(node: lastCase, message: ScaleDiagnostic.tooManyCases))
            isValid = false
        }

        return isValid ? .payloadEnum(cases) : nil
    }

    private static func parseFields(
        of structDecl: StructDeclSyntax,
        in context: some MacroExpansionContext
    ) -> [ScaleFieldModel]? {
        var fields: [ScaleFieldModel] = []
        var isValid = true

        for member in structDecl.memberBlock.members {
            guard
                let variable = member.decl.as(VariableDeclSyntax.self),
                !variable.isStatic
            else {
                continue
            }

            for binding in variable.bindings {
                guard binding.isStored else {
                    continue
                }

                // `let x = 1` can't be reassigned in init and isn't part of the wire format
                if variable.isLet, binding.initializer != nil {
                    continue
                }

                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    context.diagnose(Diagnostic(node: binding.pattern, message: ScaleDiagnostic.unsupportedPattern))
                    isValid = false
                    continue
                }

                guard let type = binding.typeAnnotation?.type else {
                    context.diagnose(Diagnostic(node: binding, message: ScaleDiagnostic.missingTypeAnnotation))
                    isValid = false
                    continue
                }

                guard
                    validateNotNestedOptional(type, in: context),
                    let marker = parseMarker(of: variable, in: context)
                else {
                    isValid = false
                    continue
                }

                if marker == .none {
                    warnIfAmbiguousBytes(type, variable: variable, in: context)
                }

                fields.append(ScaleFieldModel(name: identifier.identifier.text, coding: marker.coding))
            }
        }

        return isValid ? fields : nil
    }

    private enum Marker: Equatable {
        case none
        case vec
        case compact
        case fixed(String)

        var coding: ScaleFieldModel.Coding {
            switch self {
            case .none, .vec:
                .plain
            case .compact:
                .compact
            case let .fixed(length):
                .fixed(length)
            }
        }
    }

    /// Returns nil when the markers are invalid; diagnostics are already emitted.
    private static func parseMarker(
        of variable: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) -> Marker? {
        let markers = variable.attributes
            .compactMap { $0.as(AttributeSyntax.self) }
            .compactMap { attribute -> (AttributeSyntax, String)? in
                let name = attribute.attributeName.trimmedDescription.replacingPrefix("SubstrateScaleCodable.")
                return ["ScaleFixed", "ScaleVec", "ScaleCompact"].contains(name) ? (attribute, name) : nil
            }

        guard markers.count <= 1 else {
            context.diagnose(Diagnostic(node: variable, message: ScaleDiagnostic.conflictingMarkers))
            return nil
        }

        guard let (attribute, name) = markers.first else {
            return Marker.none
        }

        switch name {
        case "ScaleVec":
            return .vec
        case "ScaleCompact":
            return .compact
        default:
            guard
                case let .argumentList(arguments) = attribute.arguments,
                let expression = arguments.first?.expression
            else {
                return nil
            }

            if let literal = expression.as(IntegerLiteralExprSyntax.self),
               let length = Int(literal.literal.text.filter { $0 != "_" }),
               length <= 0 {
                context.diagnose(Diagnostic(node: variable, message: ScaleDiagnostic.nonPositiveFixedLength))
                return nil
            }

            return .fixed(expression.trimmedDescription)
        }
    }

    private static func validateNotNestedOptional(
        _ type: TypeSyntax,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard
            let optional = type.as(OptionalTypeSyntax.self),
            optional.wrappedType.is(OptionalTypeSyntax.self)
                || optional.wrappedType.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
        else {
            return true
        }

        context.diagnose(Diagnostic(node: type, message: ScaleDiagnostic.nestedOptional))
        return false
    }

    /// Spellings the macro knows to be `Data`. It can't see through other aliases.
    private static let ambiguousByteTokens: Set<String> = ["AccountId", "Data", "[UInt8]", "Array<UInt8>"]

    private static func warnIfAmbiguousBytes(
        _ type: TypeSyntax,
        variable: VariableDeclSyntax,
        in context: some MacroExpansionContext
    ) {
        let baseType = type.as(OptionalTypeSyntax.self)?.wrappedType ?? type
        let token = baseType.trimmedDescription
            .replacingPrefix("SubstrateSdk.")
            .replacingPrefix("Foundation.")
            .replacingPrefix("Swift.")

        guard ambiguousByteTokens.contains(token) else {
            return
        }

        context.diagnose(
            Diagnostic(
                node: variable,
                message: ScaleDiagnostic.ambiguousBytes(token),
                fixIts: [
                    addMarkerFixIt("@ScaleVec", message: "Add @ScaleVec (length-prefixed)", id: "addScaleVec", to: variable),
                    addMarkerFixIt(
                        "@ScaleFixed(32)",
                        message: "Add @ScaleFixed(32) (raw bytes)",
                        id: "addScaleFixed",
                        to: variable
                    )
                ]
            )
        )
    }

    private static func addMarkerFixIt(
        _ marker: String,
        message: String,
        id: String,
        to variable: VariableDeclSyntax
    ) -> FixIt {
        let attribute = AttributeSyntax(stringLiteral: marker)
            .with(\.leadingTrivia, variable.leadingTrivia)
            .with(\.trailingTrivia, .space)

        let elements = [AttributeListSyntax.Element.attribute(attribute)] + Array(variable.attributes)
        let fixed = variable
            .with(\.leadingTrivia, [])
            .with(\.attributes, AttributeListSyntax(elements))

        return FixIt(
            message: ScaleFixItMessage(message: message, id: id),
            changes: [.replace(oldNode: Syntax(variable), newNode: Syntax(fixed))]
        )
    }

    private static func accessModifier(of modifiers: DeclModifierListSyntax) -> String? {
        let candidates: Set<String> = ["public", "package", "open"]

        return modifiers
            .map(\.name.text)
            .first { candidates.contains($0) }
            .map { $0 == "open" ? "public" : $0 }
    }
}

private extension DeclGroupSyntax {
    var genericParameterNames: [String] {
        let clause = self.as(StructDeclSyntax.self)?.genericParameterClause
            ?? self.as(EnumDeclSyntax.self)?.genericParameterClause

        return clause?.parameters.map(\.name.text) ?? []
    }
}

private extension String {
    func replacingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}

private extension EnumCaseDeclSyntax {
    var scaleCaseAttribute: AttributeSyntax? {
        attributes.lazy
            .compactMap { $0.as(AttributeSyntax.self) }
            .first { ["ScaleCase", "SubstrateScaleCodable.ScaleCase"].contains($0.attributeName.trimmedDescription) }
    }
}

private extension AttributeSyntax {
    var integerLiteralArgument: Int? {
        guard
            case let .argumentList(arguments) = self.arguments,
            arguments.count == 1,
            let literal = arguments.first?.expression.as(IntegerLiteralExprSyntax.self)
        else {
            return nil
        }

        let text = literal.literal.text.filter { $0 != "_" }

        if text.hasPrefix("0x") {
            return Int(text.dropFirst(2), radix: 16)
        }

        if text.hasPrefix("0b") {
            return Int(text.dropFirst(2), radix: 2)
        }

        return Int(text)
    }
}

private extension VariableDeclSyntax {
    var isStatic: Bool {
        modifiers.contains { ["static", "class"].contains($0.name.text) }
    }

    var isLet: Bool {
        bindingSpecifier.tokenKind == .keyword(.let)
    }
}

private extension PatternBindingSyntax {
    var isStored: Bool {
        guard let accessorBlock else {
            return true
        }

        switch accessorBlock.accessors {
        case .getter:
            return false
        case let .accessors(accessors):
            return accessors.allSatisfy { accessor in
                [.keyword(.willSet), .keyword(.didSet)].contains(accessor.accessorSpecifier.tokenKind)
            }
        }
    }
}
