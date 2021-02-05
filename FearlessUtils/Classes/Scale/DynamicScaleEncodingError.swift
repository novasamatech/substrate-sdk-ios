import Foundation

public enum DynamicScaleEncoderError: Error {
    case unresolverType(name: String)
    case arrayExpected(json: JSON)
    case unexpectedNull
    case hexExpected(json: JSON)
    case expectedStringForCompact(json: JSON)
    case expectedStringForInt(json: JSON)
    case expectedStringForBool(json: JSON)
    case missingOptionModifier
    case unexpectedStructFields(json: JSON, expectedFields: [String])
    case unexpectedEnumJSON(json: JSON)
    case unexpectedEnumCase(value: UInt64, count: Int)
    case unexpectedTupleJSON(json: JSON)
    case unexpectedTupleComponents(count: Int, actual: Int)
}
