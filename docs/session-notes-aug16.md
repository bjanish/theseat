# Session Notes — August 16, 2026 (continued)

## Changes since v0.4.5-lifecycle (uncommitted)

If we need to revert to v0.4.5-lifecycle and re-add features, here's what was built:

### 1. Heartbeat System (SessionManager.swift)

**What it does:** Host sends `.heartbeat` to all players every 5 seconds. Player monitors: if no heartbeat received in 15 seconds, it assumes disconnection and returns to solo.

**Implementation:**
- Two properties: `heartbeatTimer: DispatchSourceTimer?` and `lastHeartbeatReceived: Date`
- `startHeartbeat()` — creates a timer, first fire at 10s, repeats every 5s. Host sends, player checks elapsed time.
- `stopHeartbeat()` — cancels the timer
- Host calls `startHeartbeat()` in `startHosting()`
- Player calls `startHeartbeat()` when connection goes `.ready` in `handlePlayerConnectionState`
- Player's `.heartbeat` handler updates `lastHeartbeatReceived = Date()`
- `stopHeartbeat()` called in: `leaveSession`, `handleDisconnect` (player side), and `tearDown`
- Logs: `[HEARTBEAT] Started (host sending/player monitoring)` and `[HEARTBEAT] No heartbeat from host in Xs — disconnecting`

### 2. Send-Failure Detection (SessionManager.swift)

**What it does:** When any `send()` completion returns an error, trigger `handleDisconnect` for that connection. Catches dead connections on the host side.

**Implementation:**
- Changed `connection.send(content: frame, completion: .contentProcessed({ _ in }))` to check for error and call `handleDisconnect` on the main queue.

### 3. Player Screen Chair (PlayerView.swift)

**What it does:** Shows GlowView (chair) at 25% opacity in the center of the player screen when no shared question is displayed.

**Implementation:**
- In the VStack body, added `else { GlowView().opacity(0.25) }` after the `currentDisplayedQuestion` check.

### 4. Toast Position Changes (SessionManager.swift)

- `"\(hostName) is in The Seat"` toast moved to `y: 0.25` (from default 0.5)
- `"\(name) is in The Seat"` (seat pass) moved to `y: 0.25`

### 5. Host Empty State (HostView.swift)

- Shows "Invite your friends\nto open **The Seat**" only when `connectedPeers.isEmpty && !peersWereNearbyAtHostStart`
- Shows "Waiting for questions..." otherwise
- `peersWereNearbyAtHostStart` flag set in `startHosting()`, reset in `tearDown()`

### 6. Suppress Empty-Seat Toast (SessionManager.swift)

- `endSession()` only shows "The Seat is empty" toast if `hadPlayers` was true (someone was connected)

### 7. Checklist Updates

- Checked off: confirmation modal, whitespace trim, background/resume test
- Deferred: solo mode (post-launch)
- Stats: 105/22, 83%

---

## Known Issue: Silent Connection Death

**Symptom:** Player joins successfully, connection reports `.ready`, but no data flows. Heartbeat times out after 15s.

**Evidence:** `nw_proto_tcp_route_init [C1.1.1.1:1] no mtu received` appears in log every time this happens.

**Root cause theory:** iOS picks AWDL or a secondary network path that immediately dies at the TCP route level. The connection object stays in `.ready` state but is effectively dead.

**Attempted fix:** `requiredInterfaceType = .wifi` — reverted because it breaks no-WiFi peer-to-peer.

**Current mitigation:** Heartbeat detects and recovers within 15 seconds.

**This did NOT happen in earlier testing.** It's unclear whether the issue is session-specific (something about the network state tonight) or was introduced by a code change. The `connectToHost` code has not changed.

**Next steps to investigate:**
1. Test on a different Wi-Fi network
2. Test with phones closer together
3. Check if the host log shows `[HEARTBEAT] Started (host sending)` — if not, the host heartbeat isn't starting
4. Consider logging every heartbeat send on the host side temporarily to confirm they're going out
