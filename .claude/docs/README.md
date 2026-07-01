# Documentation Index

> **Lazy-load model** — load only the docs relevant to the current task.
> Read the routing table below, then `Read` specific files as needed.
> The high-level subsystem map and build/test commands live in `AGENTS.md`
> (repo root); these docs go one level deeper on individual subsystems.

## Routing Table

| If the task involves...                                            | Load                     |
|-------------------------------------------------------------------|--------------------------|
| Overall layout, targets, build/test commands, conventions         | `../../AGENTS.md`        |
| Writing/running tests, XCTest→Swift Testing policy, test targets, fixtures | `tests.md`      |
| WebSocket connection lifecycle, JSON-RPC transport, reconnection, node switching, subscriptions, batching, health/ping | `web-socket-engine.md` |

_As new subsystem docs are added (SCALE codec, runtime metadata, extrinsic
building, crypto/keystore…), give each its own file here and add a routing row._

## Glossary of Load-Bearing Terms

These terms carry specific meaning across the SDK. Use them precisely:

| Term            | Meaning                                                                                          |
|-----------------|--------------------------------------------------------------------------------------------------|
| Engine          | A `JSONRPCEngine` implementation — the transport clients call to send RPC/subscriptions (`WebSocketEngine`, `HTTPEngine`) |
| Local id        | `UInt16` request id the SDK generates and returns to callers; used to cancel/track a request     |
| Remote id       | Subscription id string assigned by the node after a successful `*_subscribe` call                |
| Idempotent request | A request with `resendOnReconnect: true` — safe to replay after a drop (all subscriptions are) |
| Node switching  | Rotating `selectedURL` to the next entry in `urls` when a node is down or returns a switch-worthy error |
| Coder factory   | `RuntimeCoderFactory` — the SCALE coder/metadata provider most subsystems route through           |

## Reference Material

- `AGENTS.md` — repo-root guidance (layout, build/test, conventions); always start here
- `Package.swift` — targets, products, dependencies, test resources
- `SubstrateSdk/Classes/Network/` — networking source (engines, factories, strategies)

## Recently Changed

Most recent substantive doc-affecting changes. Older entries fall off as new ones land.

- **2026-07-01** — `subscribe(...)` gained an `options: JSONRPCOptions` parameter.
  `resendOnReconnect: false` marks a subscription non-idempotent so it is cancelled
  (not replayed) on reconnect — the subscriber is notified `unsubscribed: true`.
  Default stays `true`; existing call sites unchanged. See `web-socket-engine.md`.

- **2026-07-01** — Added reusable mocks under `Tests/Helpers/Mocks/`
  (`MockWebSocketTransport` — a Starscream `Engine` mock — plus connection
  factory, engine delegate, reconnection stub) and
  `Tests/Network/WebSocketEngineTests.swift` (Swift Testing, 15 cases). Mocks
  policy: reuse/extend shared mocks in `TestHelpers` before writing new ones
  (`tests.md` §Mocks). See `web-socket-engine.md` (Tests).
- **2026-07-01** — Added `tests.md`. Test-framework policy: **new tests use
  Swift Testing**, existing XCTest stays and is migrated opportunistically when a
  file is otherwise changed.
- **2026-07-01** — Added `web-socket-engine.md` documenting the `WebSocketEngine`
  transport (state machine, request/subscription/batch tracking, reconnection,
  node switching, health checks). Initial `.claude/docs/` index created.
