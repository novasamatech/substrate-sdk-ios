# Runtime Metadata V16 Support — Design

Date: 2026-07-16
Branch: feature/v16-metadata

## Goal

Add SCALE decoding/encoding support for Substrate runtime metadata V16 to
substrate-sdk-ios, following the existing V14/V15 architecture, and expose a
public API to look up a pallet view function by name so clients can call the
`RuntimeViewFunction_execute_view_function` runtime API.

## Source of truth

Structures verified against `frame-metadata-23.0.1/src/v16.rs` (the crate used
by polkadot-sdk) and `polkadot-sdk/substrate/frame/support/src/view_functions.rs`.

Key V15 → V16 differences (exact SCALE order matters):

- Top level: `types, pallets, extrinsic, apis, outer_enums, custom`.
  The V15 `ty` (runtime type id) field is removed.
- Pallet: adds `associated_types`, `view_functions` (both between `error` and
  `index`) and trailing `deprecation_info: ItemDeprecationInfo`.
- Pallet calls/event/error: `ty` + new `deprecation_info: EnumDeprecationInfo`.
- Storage entry: adds trailing `deprecation_info: ItemDeprecationInfo`.
  `StorageEntryType/Modifier/Hasher` unchanged (reused from V14).
- Constant: adds trailing `deprecation_info: ItemDeprecationInfo`.
- Extrinsic: `versions: Vec<u8>`, `address_ty`, `call_ty`, `signature_ty`,
  `transaction_extensions_by_version: BTreeMap<u8, Vec<Compact<u32>>>`,
  `transaction_extensions: Vec<TransactionExtensionMetadata>` where each
  extension is `identifier: String, ty, implicit` (same shape as V14's
  `SignedExtensionV14`: identifier/type/additionalSigned).
- Runtime API: adds `version: Compact<u32>` + `deprecation_info` on the trait
  and `deprecation_info` on each method. Param type is unchanged
  (`RuntimeApiMethodParamMetadata`).
- View function: `id: [u8; 32], name, inputs: Vec<FunctionParamMetadata>,
  output, docs, deprecation_info`. The id is
  `twox128(pallet_name) ++ twox128("fn_name(arg_types) -> return_type")`,
  and is passed verbatim as `ViewFunctionId` to the runtime API
  `RuntimeViewFunction_execute_view_function(id, input)`.
- Deprecation enums:
  - `ItemDeprecationInfo`: 0 `NotDeprecated`, 1 `DeprecatedWithoutNote`,
    2 `Deprecated { note: String, since: Option<String> }`.
  - `EnumDeprecationInfo`: `BTreeMap<u8, VariantDeprecationInfo>` (compact
    count + sorted key/value pairs).
  - `VariantDeprecationInfo`: explicit indices 1 `DeprecatedWithoutNote`,
    2 `Deprecated { note, since }` (index 0 unused).

## Decisions

1. **Prefix decoding, like V15.** The Swift V15 implementation intentionally
   stops after `apis`, skipping `outer_enums`/`custom`; its round-trip test
   asserts the re-encoded bytes are a prefix of the original. V16 keeps the
   same approach and skips `outer_enums`/`custom`. Everything up to and
   including `apis` is decoded exactly.
2. **Native V16 types + mapped protocol conformance.** New `*V16` structs
   mirror the wire format exactly. `RuntimeMetadataV16` conforms to
   `PostV14RuntimeMetadataProtocol` by mapping V16 pallet internals to the
   V14-shaped types the protocol requires (computed properties), and by
   mapping `TransactionExtensionMetadataV16` to `SignedExtensionV14`
   (identifier/ty/implicit ≙ identifier/type/additionalSigned). All existing
   consumer lookups (calls, storage, events, constants, signed extensions,
   runtime APIs) keep working unchanged.
3. **Runtime API lookup reuses `RuntimeApiQueryResult`.** V16 methods map to
   the existing `RuntimeApiMethodMetadata` (deprecation info dropped in the
   query result), so `getRuntimeApiMethod` keeps its signature.
4. **View function lookup by name** is added to the base
   `RuntimeMetadataProtocol` with a defaulted implementation returning `nil`
   (non-breaking for v13/v14/v15):

   ```swift
   func getViewFunction(for palletName: String, functionName: String) -> ViewFunctionQueryResult?
   ```

   `ViewFunctionQueryResult` carries the 32-byte `functionId: Data` (ready to
   send to `RuntimeViewFunction_execute_view_function`) and the full
   `PalletViewFunctionMetadataV16` (inputs/output/docs/deprecation).
5. **Version dispatch:** `RuntimeMetadataContainer` decodes `==15` as V15 and
   `>=16` as V16 (previously `>=15` fell through to V15).
6. **Test fixtures** are real chain blobs fetched via
   `state_call Metadata_metadata_at_version(16)` from Westend and Polkadot
   (both wrapped as `Option<OpaqueMetadata>`, same as the V15 fixtures).
   Both runtimes include Proxy view functions (`check_permissions`,
   `is_superset`) which the tests use for by-name lookup assertions, including
   verifying `id[0..16] == twox128("Proxy")`.

## New files

```
SubstrateSdk/Classes/Runtime/Metadata/V16/
├── RuntimeMetadataV16.swift          (top level + protocol conformance + lookups)
├── PalletMetadataV16.swift           (+ PostV14PalletMetadataProtocol mapping)
├── StorageMetadataV16.swift          (StorageMetadataV16, StorageEntryMetadataV16)
├── PalletEnumItemMetadataV16.swift   (CallMetadataV16, EventMetadataV16, ErrorMetadataV16 — ty + EnumDeprecationInfo)
├── ConstantMetadataV16.swift
├── ExtrinsicMetadataV16.swift        (+ TransactionExtensionMetadataV16, extensions-by-version map)
├── RuntimeApiMetadataV16.swift       (+ RuntimeApiMethodMetadataV16)
├── PalletAssociatedTypeMetadataV16.swift
├── PalletViewFunctionMetadataV16.swift
└── DeprecationInfoV16.swift          (ItemDeprecationInfoV16, EnumDeprecationInfoV16, VariantDeprecationInfoV16)

SubstrateSdk/Classes/Runtime/Metadata/ViewFunction/ViewFunctionQueryResult.swift
Tests/Runtime/RuntimeMetadataV16Tests.swift
Tests/Resources/Runtime/{westend,polkadot}-v16-metadata
```

Modified: `RuntimeMetadataContainer.swift` (v16 case), `RuntimeMetadata.swift`
(protocol requirement + default), `Package.swift` (fixture resources).

## Testing

- Round-trip prefix test per fixture (decode opaque → `.v16` → re-encode →
  re-encoded bytes are a prefix of the original), same as the V15 test.
- View function lookup: `getViewFunction(for: "Proxy", functionName: "is_superset")`
  returns a 32-byte id whose first 16 bytes equal `twox128("Proxy")`, with
  2 inputs and non-empty output type.
- Negative lookup returns nil; v14/v15 metadata returns nil for view functions.
- Existing protocol lookups (call/storage/constant/signed extensions/runtime
  API method) asserted against known Polkadot/Westend pallets on the V16 blob.
