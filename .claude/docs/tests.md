# Tests

## Framework policy — read first

- **New tests: use [Swift Testing](https://developer.apple.com/documentation/testing)**
  (`import Testing`, `@Test`, `#expect`, `#require`, `@Suite`).
- **Existing tests stay on XCTest.** Do not do a big-bang migration.
- **Migrate opportunistically:** when you meaningfully change an existing
  XCTest case, port that file (or the cases you touch) to Swift Testing as part
  of the same change. Leave untouched files alone.
- Both frameworks run in the same target/bundle side by side, so a target can
  hold a mix during the transition — no target split needed.

## Test targets

Defined in `Package.swift`; one test target per subsystem, each a directory
under `Tests/`:

| Target                  | Path                     | Resources                     |
|-------------------------|--------------------------|-------------------------------|
| `CommonTests`           | `Tests/Common`           | —                             |
| `CryptoTests`           | `Tests/Crypto`           | HDKD vectors                  |
| `ExtrinsicBuilderTests` | `Tests/ExtrinsicBuilder` | —                             |
| `IconTests`             | `Tests/Icon`             | —                             |
| `JsonTests`             | `Tests/JSON`             | —                             |
| `KeystoreTests`         | `Tests/Keystore`         | keystore JSON                 |
| `NetworkTests`          | `Tests/Network`          | —                             |
| `QRTests`               | `Tests/QR`               | —                             |
| `RuntimeTests`          | `Tests/Runtime`          | runtime metadata blobs        |
| `ScaleTests`            | `Tests/Scale`            | —                             |

`TestHelpers` (`Tests/Helpers`) is a **library target, not a test target** —
shared fixtures and helpers (`RuntimeHelpers`, `KeypairDeriviation`,
`JSONHelpers`, `PostV14RuntimeHelper`), reusable mocks (`Mocks/`, see below), and
the runtime resources. Test targets depend on it. Fixtures live in `Tests/Resources/` and `Resources/`, wired via
the `Resources` enum at the bottom of `Package.swift` — register any new
resource file there.

## Running tests

iOS-only package → run via `xcodebuild` against a simulator (plain `swift test`
won't work, there is no macOS platform):

```bash
# All package tests
xcodebuild test -scheme SubstrateSdk \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# A single target
xcodebuild test -scheme SubstrateSdk \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ScaleTests

# A single Swift Testing / XCTest case
xcodebuild test -scheme SubstrateSdk \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ScaleTests/FixedArrayTests
```

There is no CI workflow in this repo yet (`.github/` holds only the PR
template) — run tests locally before opening a PR.

## Writing new tests (Swift Testing)

Canonical shape — a suite with a throwing, tagged test using Given / When / Then:

```swift
import Testing
import Foundation
@testable import SubstrateSdk

@Suite("Storage key factory")
struct StorageKeyFactoryTests {
    @Test("blake128Concat key matches known vector")
    func createsExpectedKeyForBlake128ConcatHasher() throws {
        // Given
        let factory = StorageKeyFactory()
        let identifier = try Data(hexString: "8ad2a3fba7…")

        // When
        let key = try factory.createStorageKey(
            moduleName: "System",
            storageName: "Account",
            key: identifier,
            hasher: .blake128Concat
        )

        // Then
        #expect(key == (try Data(hexString: "0x26aa394e…")))
    }
}
```

Conventions:
- `#expect(...)` for assertions; `try #require(...)` to unwrap/guard before
  continuing (replaces `XCTUnwrap` and the `guard … else { XCTFail }` pattern).
- Prefer **throwing tests** (`func … throws`) over the old
  `do { … } catch { XCTFail("\(error)") }` wrapper — a thrown error fails the
  test with the error automatically.
- Use **parameterized tests** instead of loops or copy-pasted cases:
  `@Test(arguments: [...])`.
- Test-method names are plain camelCase describing behavior; the human-readable
  intent goes in the `@Test("…")` / `@Suite("…")` display name.
- Group related tests in a `@Suite` `struct` (value-type, fresh instance per
  test → natural isolation; use `init`/`deinit` for setup/teardown).

## Mocks

Reusable test doubles live in **`Tests/Helpers/Mocks/`** (part of the shared
`TestHelpers` target), one type per file, declared `public` so any test target
can use them.

- **Reuse or extend a shared mock before writing a new one.** If a shared mock is
  close but missing something, add the capability there (a new recorded field, a
  new `simulate…` helper) rather than forking a private copy into your suite.
- **Only fall back to a local double when the need is genuinely suite-specific**
  — and if it later proves reusable, promote it into `Tests/Helpers/Mocks/`.
- **Mock at the right seam.** Prefer mocking the lowest-level injectable protocol
  and exercising the real production types above it, over faking a whole
  high-level object. That keeps the real code paths under test.
- Keep mocks dumb: record inputs and expose simple accessors / `simulate…`
  helpers; put behavior/assertions in the test, not the mock.

## Test-data conventions

- Use `Data(hexString:)` for hex fixtures and `Data.random` / `Data.randomOrError`
  (from `SubstrateSdk`) for random bytes — not ad-hoc byte arrays.
- Load runtime metadata / keystore fixtures through the `TestHelpers` helpers
  rather than re-reading resource files inline.
- Use `@testable import SubstrateSdk` to reach internal types (most existing
  tests do).

## Hard rules

1. **New code ships with new tests** — and those tests are Swift Testing.
2. **Test behavior, not implementation** — assert on public outputs; only reach
   for `@testable` internals when there is no observable surface.
3. **Register fixtures in `Package.swift`** (`Resources` enum) — an unregistered
   resource silently isn't bundled and the test fails only at runtime.
4. **Don't churn passing XCTest files** just to change framework — migrate a
   file only when you're already editing it.
