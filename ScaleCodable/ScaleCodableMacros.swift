@_exported import SubstrateSdk

@attached(
    extension,
    conformances: ScaleEncodable, ScaleDecodable,
    names: named(encode(scaleEncoder:)), named(init(scaleDecoder:))
)
public macro ScaleCodable() = #externalMacro(
    module: "SubstrateScaleMacrosPlugin",
    type: "ScaleCodableMacro"
)

/// Same as `@ScaleCodable`, but decoding throws once this type is nested deeper than `maxDepth`
/// on the current thread. Use it on recursive types fed untrusted input: unbounded recursion
/// overflows the stack after a few hundred levels.
@attached(
    extension,
    conformances: ScaleEncodable, ScaleDecodable,
    names: named(encode(scaleEncoder:)), named(init(scaleDecoder:))
)
public macro ScaleCodable(maxDepth: Int) = #externalMacro(
    module: "SubstrateScaleMacrosPlugin",
    type: "ScaleCodableMacro"
)

/// Wire index of an enum case. Either every case of an enum has it, or none does
/// (then indices follow declaration order).
@attached(peer)
public macro ScaleCase(_ index: UInt8) = #externalMacro(
    module: "SubstrateScaleMacrosPlugin",
    type: "ScaleMarkerMacro"
)

/// Raw `length` bytes without a length prefix (Rust `[u8; N]`); encoding throws on a length mismatch.
@attached(peer)
public macro ScaleFixed(_ length: Int) = #externalMacro(
    module: "SubstrateScaleMacrosPlugin",
    type: "ScaleMarkerMacro"
)

/// Length-prefixed bytes (Rust `Vec<u8>`). Encodes exactly like an unmarked `Data`;
/// it records the intent and silences the ambiguous-bytes warning.
@attached(peer)
public macro ScaleVec() = #externalMacro(
    module: "SubstrateScaleMacrosPlugin",
    type: "ScaleMarkerMacro"
)

/// Compact encoding for unsigned integers, their optionals and arrays.
@attached(peer)
public macro ScaleCompact() = #externalMacro(
    module: "SubstrateScaleMacrosPlugin",
    type: "ScaleMarkerMacro"
)
