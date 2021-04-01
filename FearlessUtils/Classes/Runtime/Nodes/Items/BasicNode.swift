import Foundation

public class U8Node: Node {
    public var typeName: String { PrimitiveType.u8.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU8(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU8()
    }
}

public class U16Node: Node {
    public var typeName: String { PrimitiveType.u16.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU16(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU16()
    }
}

public class U32Node: Node {
    public var typeName: String { PrimitiveType.u32.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU32(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU32()
    }
}

public class U64Node: Node {
    public var typeName: String { PrimitiveType.u64.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU64(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU64()
    }
}

public class U128Node: Node {
    public var typeName: String { PrimitiveType.u128.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU128(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU128()
    }
}

public class U256Node: Node {
    public var typeName: String { PrimitiveType.u256.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendU256(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readU256()
    }
}

public class BoolNode: Node {
    public var typeName: String { PrimitiveType.bool.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendBool(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readBool()
    }
}

public class StringNode: Node {
    public var typeName: String { PrimitiveType.string.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        try encoder.appendString(json: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        try decoder.readString()
    }
}
