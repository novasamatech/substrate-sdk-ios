import SwiftSyntax
import SwiftSyntaxBuilder

enum ScaleCodeGenerator {
    private static let field = "SubstrateScaleCodable.ScaleField"
    private static let compact = "SubstrateScaleCodable.ScaleCompact"
    private static let fixedBytes = "SubstrateScaleCodable.ScaleFixedBytes"
    private static let codable = "SubstrateSdk.ScaleEncodable & SubstrateSdk.ScaleDecodable"
    private static let unexpectedValue = "SubstrateSdk.ScaleCodingError.unexpectedDecodedValue"

    static func extensionDecl(
        for model: ScaleTypeModel,
        extending type: some TypeSyntaxProtocol
    ) throws -> ExtensionDeclSyntax {
        let access = model.accessModifier.map { "\($0) " } ?? ""

        let encodeBody: String
        var decodeBody: String

        switch model.kind {
        case let .structure(fields):
            encodeBody = structEncodeBody(fields)
            decodeBody = structDecodeBody(fields)
        case let .payloadEnum(cases):
            encodeBody = enumEncodeBody(cases)
            decodeBody = enumDecodeBody(cases)
        case .rawValueEnum:
            encodeBody = "try self.rawValue.encode(scaleEncoder: scaleEncoder)"
            decodeBody = """
            guard let value = Self(rawValue: try UInt8(scaleDecoder: scaleDecoder)) else {
                throw \(unexpectedValue)
            }
            self = value
            """
        }

        if let maxDepth = model.maxDepth {
            decodeBody = """
            try SubstrateScaleCodable.ScaleDecodingDepth.enter(Self.self, limit: \(maxDepth))
            defer {
                SubstrateScaleCodable.ScaleDecodingDepth.leave(Self.self)
            }
            """ + (decodeBody.isEmpty ? "" : "\n" + decodeBody)
        }

        let whereClause = model.genericParameters.isEmpty
            ? ""
            : " where " + model.genericParameters.map { "\($0): \(codable)" }.joined(separator: ", ")

        let source = """
        extension \(type.trimmedDescription): SubstrateSdk.ScaleEncodable, SubstrateSdk.ScaleDecodable\(whereClause) {
            \(access)func encode(scaleEncoder: any SubstrateSdk.ScaleEncoding) throws {
        \(indented(encodeBody, by: 8))
            }

            \(access)init(scaleDecoder: any SubstrateSdk.ScaleDecoding) throws {
        \(indented(decodeBody, by: 8))
            }
        }
        """

        return try ExtensionDeclSyntax("\(raw: source)")
    }

    private static func indented(_ body: String, by width: Int) -> String {
        let padding = String(repeating: " ", count: width)

        return body
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : padding + $0 }
            .joined(separator: "\n")
    }

    private static func structEncodeBody(_ fields: [ScaleFieldModel]) -> String {
        fields
            .map { field in
                switch field.coding {
                case .plain:
                    "try \(Self.field).encode(self.\(field.name), to: scaleEncoder)"
                case .compact:
                    "try \(compact).encode(self.\(field.name), to: scaleEncoder)"
                case let .fixed(length):
                    "try \(fixedBytes).encode(self.\(field.name), length: \(length), to: scaleEncoder)"
                }
            }
            .joined(separator: "\n")
    }

    private static func structDecodeBody(_ fields: [ScaleFieldModel]) -> String {
        fields
            .map { field in
                switch field.coding {
                case .plain:
                    "self.\(field.name) = try \(Self.field).decode(from: scaleDecoder)"
                case .compact:
                    "self.\(field.name) = try \(compact).decode(from: scaleDecoder)"
                case let .fixed(length):
                    "self.\(field.name) = try \(fixedBytes).decode(length: \(length), from: scaleDecoder)"
                }
            }
            .joined(separator: "\n")
    }

    private static func enumEncodeBody(_ cases: [ScaleCaseModel]) -> String {
        let branches = cases.map { scaleCase in
            let bindings = scaleCase.payload.indices.map { "p\($0)" }
            let pattern = bindings.isEmpty
                ? "case .\(scaleCase.name):"
                : "case let .\(scaleCase.name)(\(bindings.joined(separator: ", "))):"
            let statements = ["try UInt8(\(scaleCase.index)).encode(scaleEncoder: scaleEncoder)"]
                + bindings.map { "try \(field).encode(\($0), to: scaleEncoder)" }

            return ([pattern] + statements.map { "    " + $0 }).joined(separator: "\n")
        }

        return (["switch self {"] + branches + ["}"]).joined(separator: "\n")
    }

    private static func enumDecodeBody(_ cases: [ScaleCaseModel]) -> String {
        let branches = cases.map { scaleCase in
            let decodes = scaleCase.payload.enumerated().map { offset, payload in
                "let p\(offset): \(payload.type.trimmedDescription) = try \(field).decode(from: scaleDecoder)"
            }
            let arguments = scaleCase.payload.enumerated().map { offset, payload in
                payload.label.map { "\($0): p\(offset)" } ?? "p\(offset)"
            }
            let construction = arguments.isEmpty
                ? "self = .\(scaleCase.name)"
                : "self = .\(scaleCase.name)(\(arguments.joined(separator: ", ")))"

            return (["case \(scaleCase.index):"] + (decodes + [construction]).map { "    " + $0 })
                .joined(separator: "\n")
        }

        let defaultBranch = ["default:", "    throw \(unexpectedValue)"]

        return (["switch try UInt8(scaleDecoder: scaleDecoder) {"] + branches + defaultBranch + ["}"])
            .joined(separator: "\n")
    }
}
