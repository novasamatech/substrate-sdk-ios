# AGENTS.md — substrate-sdk-ios

Guidance for AI agents working **inside** this repository. This is the
`SubstrateSdk` library itself (Nova Wallet's Substrate/Polkadot SDK for iOS) —
not an app that consumes it. It provides SCALE codec, runtime metadata parsing,
JSON-RPC networking, storage queries/subscriptions, extrinsic building/signing,
crypto/keystore, and QR/identicon utilities.

## Layout

Distributed as an SPM package only (`Package.swift`, swift-tools 6.0, Swift 5
language mode, iOS 14+). CocoaPods is no longer supported. Five products, each a
top-level directory / SPM target:

| Target (product)                | Path                 | Depends on                          | Purpose |
|---------------------------------|----------------------|-------------------------------------|---------|
| `SubstrateSdk`                  | `SubstrateSdk/Classes` | (core deps)                       | Core: SCALE, runtime, network, extrinsic, crypto, keystore, QR, icon |
| `SubstrateStorageQuery`         | `StorageQuery`       | `SubstrateSdk`                      | One-shot & prefix storage reads (`StorageRequestFactory`) |
| `SubstrateStorageSubscription`  | `StorageSubscription`| `SubstrateSdk`, `SubstrateStorageQuery` | Batched storage subscriptions (`CallbackBatchStorageSubscription`) |
| `SubstrateStateCall`            | `StateCall`          | `SubstrateSdk`                      | Runtime API (`state_call`) execution |
| `SubstrateMetadataHash`         | `MetadataHash`       | `SubstrateSdk`, metadata-shortener | CheckMetadataHash / metadata shortening |

Core (`SubstrateSdk/Classes`) subsystems:
- **Scale/** — `DynamicScaleEncoder`/`DynamicScaleDecoder`, `ScaleCodable`, per-type
  encoders in `Scale/Encodable/`, SCALE types in `Scale/Types/` (Era, MultiAddress, H256…).
- **Runtime/** — metadata parsing (`Metadata/V14`, `V15`, `PostV14`, `RuntimeApi`),
  type registry & resolution (`TypeRegistry`, `TypeRegistryCatalog`, `SiTypeRegistry`),
  `CodingFactory/RuntimeCoderFactory` (the coder factory everything routes through).
- **Extrinsic/** — `ExtrinsicBuilder`, `RuntimeCall`, `CallBuilder/`, and
  `TransactionExtension/` (signed extensions: CheckGenesis, CheckMortality,
  CheckMetadataHash, ChargeTransactionPayment, ChargeAssetTxPayment, VerifySignature…).
- **Network/** — `JSONRPCEngine`, `WebSocketEngine` (Starscream), `HTTPEngine`,
  reconnection/node-switching, `Reachability`.
- **Crypto/**, **Signing/**, **Keystore/** — keypair factories (sr25519/ed25519/ecdsa),
  BIP32/junction derivation, signing wrappers, keystore encode/decode (Scrypt).
- **Primitives/**, **Pallets/**, **QR/**, **Icon/** — AccountId/address helpers,
  known pallet models (System, Utility, Orml…), Substrate QR codec, Polkadot/Nova identicons.

Tests live in `Tests/` (one target per subsystem, see `Package.swift`). Fixtures
are in `Resources/` (runtime metadata blobs, keystores, HDKD vectors) and wired
via the `Resources` enum at the bottom of `Package.swift`.

## Build & test

iOS-only package, so use `xcodebuild` against a simulator (plain `swift test`
won't work — there is no macOS platform):

```bash
# SPM (scheme `SubstrateSdk`; `SubstrateMetadataHash` is a separate scheme)
xcodebuild test -scheme SubstrateSdk \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Verify scheme names with `xcodebuild -list`.

`swift build` may succeed for dependency resolution, but validate real changes by
running the relevant `Tests/<Subsystem>` target. When adding a new test resource,
register it in the `Resources` enum in `Package.swift`.

## Conventions & rules

These reflect how the SDK is meant to be used and extended (distilled from
downstream Nova Wallet review history):

- **Route decoding through the coder factory.** New SCALE work should go through
  `RuntimeCoderFactory`/`DynamicScaleDecoder`, not ad-hoc byte parsing. Implement
  `ScaleEncodable`/`ScaleDecodable` at the type level for reuse rather than
  decoding inline.
- **Never silently fall back to raw bytes.** When decoding expectations aren't
  met, throw an explicit error (see `DynamicScaleCodingError`, `ScaleCodingError`).
- **Transaction-extension ordering matters.** Base/default extensions come first,
  custom overrides after — a later extension must be able to override an earlier
  one. Respect this when touching `ExtrinsicBuilder` / `TransactionExtension`.
- **Hex conversion:** use the `Data` wrappers (`Data(hexString:)`, `Data.toHex(includePrefix:)`)
  from `Primitives/Data+Hex.swift`, not the underlying `NSData` helpers from NovaCrypto.
  Use `Data.random`/`Data.randomOrError` for test/random data.
- **Match surrounding style.** Files are grouped by subsystem with `+`-suffixed
  extension files (e.g. `RuntimeCall+JSON.swift`, `CallMetadata+TypeCheck.swift`).
  New generic helpers belong in the subsystem they extend.

## PRs

Follow `.github/PULL_REQUEST_TEMPLATE.md` (SUMMARY + SOLUTION sections, self-review
checkbox). Tag releases from `master` (the main branch); consumers pin the SDK by
git tag / SPM version.
