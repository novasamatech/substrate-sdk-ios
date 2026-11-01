# SCALE codable macros (`SubstrateScaleCodable`)

Opt-in product that synthesizes static `ScaleEncodable`/`ScaleDecodable`
conformances. Nothing changes for consumers that don't import it.

**Use it only for fixed-layout types**: app wire protocols, stable runtime-API
results, local cache records. Calls, events and storage values whose layout
depends on the runtime must keep going through `RuntimeCoderFactory`.

## Pieces

| Path | Role |
|------|------|
| `ScaleCodable/ScaleCodableMacros.swift` | Public macro declarations; `@_exported import SubstrateSdk` |
| `ScaleCodable/ScaleField.swift`, `ScaleCompact.swift`, `ScaleFixedBytes.swift` | Runtime helpers the expansion calls |
| `ScaleMacros/` (`SubstrateScaleMacrosPlugin`, host-only) | `ScaleCodableMacro` (extension macro), `ScaleMarkerMacro` (no-op peer), `ScaleParser` → `ScaleModel` → `ScaleCodeGenerator`, `ScaleDiagnostic` |

## Semantics

- Structs: stored instance properties in declaration order. Static and
  computed properties, and `let x = …` with an initializer, are skipped.
  An explicit type annotation is required.
- Enums: a `UInt8` index, then the payload in order. Either every case has
  `@ScaleCase(n)` or none does (then the index is the declaration position).
  An unknown index throws `ScaleCodingError.unexpectedDecodedValue`.
  `enum X: UInt8` uses `rawValue` as the index; other raw types are rejected.
- Markers on struct properties: `@ScaleFixed(n)` (raw bytes, encode throws on a
  length mismatch), `@ScaleVec` (length-prefixed, same bytes as unmarked),
  `@ScaleCompact` (unsigned ints, `BigUInt`, their optionals and arrays). Only one
  marker per property. Swift doesn't allow attributes on enum payloads, so use a
  wrapper struct instead.
- `T?` → `Option<T>` (`00` / `01 ++ value`); `Bool?` → a single byte `00/01/02`.
  `Optional` deliberately has **no** `ScaleCodable` conformance (it would make
  `Bool?` 2 bytes and the helper overloads ambiguous). `T??` is rejected.
- Generic parameters are all constrained to `ScaleEncodable & ScaleDecodable`.
- Witnesses copy `public`/`package` from the type and are emitted in the
  extension, so the memberwise init survives.

## Key design rule

The macro only sees syntax, never types. It chooses *which helper* to call, and
the compiler's overload resolution chooses *which overload* runs. Never branch
on spelled type names for behaviour. The one exception is the
**ambiguous-bytes warning**: unmarked `AccountId`, `Data` or `[UInt8]` properties
get a warning with fix-its (`@ScaleVec` / `@ScaleFixed(32)`). It forces an
explicit choice, because `AccountId` is `Data` (`Vec<u8>`) but often means raw
32 bytes on the wire.

## Adding a feature

1. Add an expansion test in `Tests/ScaleMacrosPlugin` (macOS scheme) and a
   byte-level behaviour test in `Tests/ScaleCodable` (iOS) and watch both fail.
2. Extend the model, parser (diagnose instead of guessing) and generator.
3. Prefer a new runtime-helper overload over generated logic.
