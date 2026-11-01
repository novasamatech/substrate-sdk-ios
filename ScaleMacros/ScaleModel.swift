import SwiftSyntax

struct ScaleTypeModel {
    enum Kind {
        case structure([ScaleFieldModel])
        case payloadEnum([ScaleCaseModel])
        case rawValueEnum
    }

    let accessModifier: String?
    let genericParameters: [String]
    /// Limit expression as written; nil when depth isn't guarded.
    let maxDepth: String?
    let kind: Kind
}

struct ScaleFieldModel {
    enum Coding {
        case plain
        case compact
        /// Length expression as written, e.g. `32` or `Self.length`.
        case fixed(String)
    }

    let name: String
    let coding: Coding
}

struct ScaleCaseModel {
    let name: String
    let index: Int
    let payload: [ScalePayloadModel]
}

struct ScalePayloadModel {
    let label: String?
    let type: TypeSyntax
}
