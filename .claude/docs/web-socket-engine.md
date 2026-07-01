# WebSocketEngine

The default `JSONRPCEngine` transport for talking to a Substrate node over a
WebSocket. Owns a single live socket, a connection state machine, request /
subscription / batch bookkeeping, automatic reconnection, multi-URL node
switching, and periodic health checks.

**Source:** `SubstrateSdk/Classes/Network/`
- `WebSocketEngine.swift` — core: state, init, connect/disconnect, request & subscription bookkeeping, reconnection/node-switch, ping
- `WebSocketEngine+Protocol.swift` — the public `JSONRPCEngine` conformance (`callMethod`, `subscribe`, batch, cancel)
- `WebSocketEngine+Delegate.swift` — Starscream `WebSocketDelegate`, reachability, and scheduler callbacks
- `JSONRPCEngine.swift` — protocol, request/subscription/batch model types, `JSONRPCOptions`, errors
- `WebSocketConnectionFactory.swift` — builds the underlying Starscream `WebSocket`
- `ReconnectionStrategy.swift` — `ExponentialReconnection`
- `JSONRPCNodeSwitching.swift` — error-code-driven node switching
- `Health.swift` / `RPCMethod.swift` — `HealthCheckMethod`, `system_health`, `state_unsubscribeStorage`

## Responsibilities

- Maintain one WebSocket connection to `selectedURL`, one of an ordered `urls` list.
- Expose the `JSONRPCEngine` API: `callMethod`, `subscribe`, batching, `cancelForIdentifiers`.
- Queue requests issued while disconnected/connecting and flush them on connect.
- Track in-flight requests and active subscriptions so they survive drops.
- Reconnect with backoff; rotate to the next node when one looks down or returns a switch-worthy error.
- Keep the socket alive with pings (WebSocket ping/pong or a Substrate `system_health` call).

## Connection state machine

`WebSocketEngine.State` (Equatable):

```
notConnected(url:) ──connect──▶ connecting(url:) ──.connected event──▶ connected(url:)
       ▲                              │                                      │
       │                    error/cancel/disconnect                error/cancel/disconnect
       │                              ▼                                      ▼
       └───────── waitingReconnection(url:) ◀── scheduleReconnectionOrDisconnect ──┘
```

- **`notConnected`** — idle. A new request triggers `startConnecting`.
- **`connecting`** — socket opening; requests are queued in `pendingRequests`.
- **`connected`** — requests are written immediately; ping loop runs.
- **`waitingReconnection`** — a reconnection is scheduled on `reconnectionScheduler`; a fresh request or network-reachable event cancels the wait and connects now.

Every assignment to `state` fires `delegate.webSocketDidChangeState(_:from:to:)` on `completionQueue`.

## Concurrency model

- All public entry points and all delegate/scheduler callbacks take `mutex`
  (`NSLock`) — mutation of engine state is fully serialized. **Do not call an
  internal `WebSocketEngine` method without already holding `mutex`.**
- Two dispatch queues (both default to the shared `JSONRPCEngineShared.processingQueue`,
  label `com.nova.ws.processing`):
  - `processingQueue` — where Starscream delivers socket events (the connection's
    `callbackQueue`) and where the schedulers fire.
  - `completionQueue` — where caller completion handlers, subscription updates,
    and delegate callbacks are dispatched.
- Because they default to the same serial queue, socket-event handling and
  caller callbacks are serialized together. Passing a distinct `processingQueue`
  separates them.

## Lifecycle & public API

Construction (`init?`) returns `nil` if `urls` is empty. Key knobs (with defaults):
`connectionFactory` (`WebSocketConnectionFactory`), `customNodeSwitcher` (nil),
`reachabilityManager` (nil), `reconnectionStrategy` (`ExponentialReconnection()`),
`healthCheckMethod` (`.websocketPingPong`), `autoconnect` (`true`),
`connectionTimeout` (10s), `pingInterval` (30s), `name`, `logger`. With
`autoconnect` it calls `connectIfNeeded()` immediately.

- **`connectIfNeeded()`** — connects from `notConnected`; from `waitingReconnection` cancels the timer and connects now; otherwise no-op.
- **`disconnectIfNeeded(_ force:)`** — moves to `notConnected`, cancels in-flight work (see below), and either graceful-closes (`CloseCode.goingAway`) or hard-resets the socket.
- **`changeUrls(_:)`** — disconnect, replace `urls`, reset `selectedURLIndex`/`reconnectionAttempts`, rebuild the connection, reconnect.
- **`JSONRPCEngine` methods** (`WebSocketEngine+Protocol.swift`): `callMethod`, `subscribe`, `addBatchCallMethod`/`submitBatch`/`clearBatch`, `cancelForIdentifiers`. All lock `mutex`, generate a local id, and route through `updateConnectionForRequest`.
- `deinit` detaches the delegate, force-disconnects, and cancels both schedulers.

## Request routing (`updateConnectionForRequest`)

Depending on `state`:
- `connected` → `send(request:)` immediately.
- `connecting` / `notConnected` → append to `pendingRequests` (and start connecting if `notConnected`).
- `waitingReconnection` → append to pending, cancel the reconnection timer, and start connecting now (don't make a user request wait out the backoff).

`send(request:)` records the request in `inProgressRequests` keyed by each item id
(a batch registers all its item ids → the same request) and writes the JSON to the socket.
On `connected`, `sendAllPendingRequests()` flushes the queue.

## Local vs remote ids

- **Local id** (`UInt16`) — generated by `generateRequestId()`, returned to the caller, used to cancel/track. `generateRequestId` avoids collisions with all pending, in-progress, subscription, and partial-batch ids.
- **Remote id** (`String`) — a subscription id the node returns in the response to a `*_subscribe` call. Stored on the `JSONRPCSubscribing` as `remoteId`; subsequent update notifications are matched by remote id.

## Incoming data (`process(data:)`)

1. Try to decode a single `JSONRPCBasicData`:
   - has an `identifier` + `error` → `processErrorAndResetIfNeeded`;
   - has an `identifier`, no error → `completeRequestForRemoteId` (fulfils a request and/or captures a subscription's remote id);
   - no `identifier` → it's a subscription update → `processSubscriptionUpdate`.
2. Otherwise decode a JSON array (batch response), split into per-item responses keyed by id, complete each, then run `processErrorsInBatch`.

**Subscription-update ordering race:** a subscription update can arrive *before*
the `*_subscribe` response that tells us the remote id. `processSubscriptionUpdate`
handles this by buffering updates for an unknown remote id in
`pendingSubscriptionResponses[remoteId]`; when the subscribe response lands,
`processSubscriptionResponse` replays the buffered updates. Preserve this buffering.

## Reconnection & node switching

`scheduleReconnectionOrDisconnect(attempt:after:)` is the hub:
- If `attempt > 1` the current node is treated as down → `switchNode()` (rotate `selectedURL`), and the returned attempt count is used.
- Ask `reconnectionStrategy.reconnectAfter(attempt:)`. If it returns a delay → state `waitingReconnection`, arm `reconnectionScheduler`. If it returns `nil` (give up) → state `notConnected` and every pending request is failed with the error (or `JSONRPCEngineError.unknownError`).
- `ExponentialReconnection.reconnectAfter` = `multiplier * exp(attempt)` (default multiplier `0.3`), and never returns nil, so by default the engine retries forever.

`switchNode()` detaches/force-disconnects, advances `selectedURLIndex` modulo
`urls.count`, rebuilds the connection, and — when `urls.count > 1` — notifies
`delegate.webSocketDidSwitchURL`. Reconnection attempt counts are tracked
per-URL in `reconnectionAttempts`.

**Custom node switching by RPC error:** `JSONRPCNodeSwitching` /
`JSONRRPCodeNodeSwitcher(codes:)` lets specific JSON-RPC error codes force an
immediate node switch (`resetRequestsAndSwitchNode`) instead of surfacing the
error to the caller. Wired through `processErrorAndResetIfNeeded`.

**Reachability:** if a `reachabilityManager` is supplied and the network becomes
reachable while in `waitingReconnection`, the engine cancels the backoff timer
and reconnects immediately.

## Resetting in-flight work on a drop (`resetInProgress`)

On any disconnect/error/cancel while connected:
- Requests with `resendOnReconnect: true` (idempotent) are moved back to `pendingRequests` to be replayed.
- Requests with `resendOnReconnect: false` that have a response handler are returned as *notifiable* and failed with an error (`clientCancelled` / `remoteCancelled` / `unknownError` depending on cause).
- `rescheduleActiveSubscriptions()` clears each active subscription's `remoteId` and re-queues its original subscribe request, so subscriptions transparently re-establish after reconnect. **Subscriptions always use `resendOnReconnect: true`.**

## Health checks / ping

While `connected`, `schedulePingIfNeeded()` arms `pingScheduler` every
`pingInterval` (skipped if `pingInterval <= 0`). `sendPing()` dispatches per
`healthCheckMethod`:
- `.websocketPingPong` → `connection.write(ping:)`; inbound pings are answered with `write(pong:)`.
- `.substrate` → a `system_health` RPC call (`resendOnReconnect: false`); the result only logs a warning if the node reports `isSyncing`.

## Delegate

`WebSocketEngineDelegate` (weak):
- `webSocketDidChangeState(_:from:to:)` — every state transition.
- `webSocketDidSwitchURL(_:newUrl:)` — only when a switch happens and `urls.count > 1`.

## Tests

`Tests/Network/WebSocketEngineTests.swift` (Swift Testing) covers the engine
end-to-end without a real socket. It mocks at the **correct seam**: Starscream's
low-level `Engine` transport, not the whole `WebSocket`. The shared mocks live in
`Tests/Helpers/Mocks/` (`TestHelpers` target):
- `MockWebSocketTransport` implements Starscream's `Engine` — records outbound
  frames (`sentRequests`, `pingCount`, `pongCount`) and lifecycle
  (`startCount`, `stopCloseCodes`), and exposes `simulate…` helpers to push inbound events.
- `MockWebSocketConnectionFactory` hands the SDK a **real** `WebSocket` built
  around that transport, so the production `WebSocket` (state forwarding,
  `callbackQueue` delivery) is exercised — only the wire is faked. It records
  every connection in `transports` (use `latest` for the current one).
- `MockWebSocketEngineDelegate`, `StubReconnectionStrategy` complete the wiring.

**Synchronization:** the engine is built with a dedicated serial `processingQueue`.
Pushing an event hops through the real `WebSocket` onto that queue and the engine
re-dispatches completions onto it, so the `Harness` drains it with a few
`queue.sync {}` passes before asserting. Passing your own queue (not the shared
`JSONRPCEngineShared.processingQueue`) is what makes async delivery deterministic
and keeps parallel tests isolated.

Covered behaviors: nil init on empty urls, autoconnect, connect/queue/flush,
success & error result delivery, subscription remote-id capture + update routing,
unsubscribe on cancel, subscription replay across reconnect, give-up failing
pending requests, node switching via `JSONRPCNodeSwitching`, graceful disconnect,
inbound ping→pong.

## Extending / gotchas

- **Hold `mutex`.** Public methods and delegate callbacks lock it; internal
  helpers assume it's held. Adding a new public method → lock/`defer` unlock like the others.
- **Respect `resendOnReconnect`.** It's the contract for what survives a drop.
  Reads/subscriptions should be idempotent; one-shot side-effecting calls should not.
- **Preserve the pending-subscription-response buffer** — removing it reintroduces the update-before-subscribe-ack race.
- **Injection points for tests:** `WebSocketConnectionFactoryProtocol` (swap the
  socket), `ReconnectionStrategyProtocol`, `JSONRPCNodeSwitching`,
  `ReachabilityManagerProtocol`. `WebSocketConnectionProtocol` abstracts Starscream's `WebSocket`.
- **State changes fire delegate callbacks on `completionQueue`** — don't assume they run inline with the mutation.
