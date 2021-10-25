import Foundation

public protocol DynamicScaleEncoding {
    func append(json: JSON, type: String) throws
    func appendOption(json: JSON, type: String) throws
    func appendVector(json: JSON, type: String) throws
    func appendCompact(json: JSON, type: String) throws
    func appendFixedArray(json: JSON, type: String) throws
    func appendBytes(json: JSON) throws
    func appendString(json: JSON) throws
    func appendU8(json: JSON) throws
    func appendU16(json: JSON) throws
    func appendU32(json: JSON) throws
    func appendU64(json: JSON) throws
    func appendU128(json: JSON) throws
    func appendU256(json: JSON) throws
    func appendI8(json: JSON) throws
    func appendI16(json: JSON) throws
    func appendI32(json: JSON) throws
    func appendI64(json: JSON) throws
    func appendI128(json: JSON) throws
    func appendI256(json: JSON) throws
    func appendBool(json: JSON) throws
    func append<T: ScaleCodable>(encodable: T) throws

    func newEncoder() -> DynamicScaleEncoding

    func encode() throws -> Data
}

public protocol DynamicScaleEncodable {
    func accept(encoder: DynamicScaleEncoding, value: JSON) throws
}

public protocol DynamicScaleDecoding {
    var remained: Int { get }
    func read(type: String) throws -> JSON
    func readOption(type: String) throws -> JSON
    func readVector(type: String) throws -> JSON
    func readCompact(type: String) throws -> JSON
    func readFixedArray(type: String, length: UInt64) throws -> JSON
    func readBytes(length: Int) throws -> JSON
    func readString() throws -> JSON
    func readU8() throws -> JSON
    func readU16() throws -> JSON
    func readU32() throws -> JSON
    func readU64() throws -> JSON
    func readU128() throws -> JSON
    func readU256() throws -> JSON
    func readI8() throws -> JSON
    func readI16() throws -> JSON
    func readI32() throws -> JSON
    func readI64() throws -> JSON
    func readI128() throws -> JSON
    func readI256() throws -> JSON
    func readBool() throws -> JSON
    func read<T: ScaleCodable>() throws -> T
}

public protocol DynamicScaleDecodable {
    func accept(decoder: DynamicScaleDecoding) throws -> JSON
}

public typealias DynamicScaleCodable = DynamicScaleEncodable & DynamicScaleDecodable

enum ScaleCodingModifier {
    case compact
}
