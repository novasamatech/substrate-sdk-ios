import SwiftDiagnostics

enum ScaleDiagnostic: DiagnosticMessage {
    case unsupportedDeclaration
    case missingTypeAnnotation
    case unsupportedPattern
    case mixedCaseIndices
    case duplicateIndex(Int, existingCase: String)
    case scaleCaseOnRawValueEnum
    case unsupportedRawType
    case nonLiteralIndex
    case scaleCaseOnMultipleElements
    case tooManyCases
    case conflictingMarkers
    case nonPositiveFixedLength
    case nestedOptional
    case ambiguousBytes(String)
    case nonPositiveMaxDepth

    var message: String {
        switch self {
        case .unsupportedDeclaration:
            "@ScaleCodable supports only structs and enums"
        case .missingTypeAnnotation:
            "Explicit type annotation required"
        case .unsupportedPattern:
            "Unsupported property declaration"
        case .mixedCaseIndices:
            "Either all cases or none must have @ScaleCase"
        case let .duplicateIndex(index, existingCase):
            "Duplicate SCALE variant index \(index) (also used by '\(existingCase)')"
        case .scaleCaseOnRawValueEnum:
            "@ScaleCase is not allowed on raw-value enums; the raw value is the index"
        case .unsupportedRawType:
            "Raw-value enums must use UInt8 raw values"
        case .nonLiteralIndex:
            "@ScaleCase expects an integer literal"
        case .scaleCaseOnMultipleElements:
            "@ScaleCase must annotate a single case; split the declaration"
        case .tooManyCases:
            "SCALE enums support at most 256 cases"
        case .conflictingMarkers:
            "Use only one of @ScaleFixed, @ScaleVec, @ScaleCompact"
        case .nonPositiveFixedLength:
            "@ScaleFixed length must be positive"
        case .nestedOptional:
            "Nested optionals are not supported"
        case let .ambiguousBytes(token):
            "'\(token)' encodes as length-prefixed Vec<u8>; mark it @ScaleVec or @ScaleFixed(n)"
        case .nonPositiveMaxDepth:
            "maxDepth must be positive"
        }
    }

    var diagnosticID: MessageID {
        let id = switch self {
        case .unsupportedDeclaration: "unsupportedDeclaration"
        case .missingTypeAnnotation: "missingTypeAnnotation"
        case .unsupportedPattern: "unsupportedPattern"
        case .mixedCaseIndices: "mixedCaseIndices"
        case .duplicateIndex: "duplicateIndex"
        case .scaleCaseOnRawValueEnum: "scaleCaseOnRawValueEnum"
        case .unsupportedRawType: "unsupportedRawType"
        case .nonLiteralIndex: "nonLiteralIndex"
        case .scaleCaseOnMultipleElements: "scaleCaseOnMultipleElements"
        case .tooManyCases: "tooManyCases"
        case .conflictingMarkers: "conflictingMarkers"
        case .nonPositiveFixedLength: "nonPositiveFixedLength"
        case .nestedOptional: "nestedOptional"
        case .ambiguousBytes: "ambiguousBytes"
        case .nonPositiveMaxDepth: "nonPositiveMaxDepth"
        }

        return MessageID(domain: "SubstrateScaleMacros", id: id)
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .ambiguousBytes:
            .warning
        default:
            .error
        }
    }
}

struct ScaleFixItMessage: FixItMessage {
    let message: String
    let id: String

    var fixItID: MessageID {
        MessageID(domain: "SubstrateScaleMacros", id: id)
    }
}
