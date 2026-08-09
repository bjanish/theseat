# Networking Reference (from HCF GameManager)

## Critical Pattern: ALL queues are .main in HCF

HCF runs listener, browser, and all connections on `.main`. It uses `Task { @MainActor in }` inside callbacks as a formality. This works because HCF's GameManager inherits from NSObject — NOT @Observable.

**TheSeat uses @Observable** — this is the source of all UI freeze issues. The @Observable macro adds property tracking overhead that conflicts with networking callbacks on .main.

**Solution for TheSeat:** Use a single background `networkQueue` for all NWConnection/NWBrowser/NWListener start calls. Use `DispatchQueue.main.async` ONLY for final state mutations (role change, toast, peer list update). The receive loop recursion stays on the networkQueue — only the handleMessage/handleDisconnect hops to main.

---

## receiveLoop Pattern (PROVEN)

```swift
connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { data, _, _, error in
    guard let data, error == nil else {
        // nil data OR error = disconnect
        handleDisconnect(connection)
        return
    }
    let length = data.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
    
    connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { body, _, _, error in
        guard let body, error == nil else {
            handleDisconnect(connection)
            return
        }
        // Decode and handle on main
        DispatchQueue.main.async {
            if let message = decode(body) {
                handleMessage(message, from: connection)
            }
            receiveLoop(on: connection)  // RECURSE AFTER handling
        }
    }
}
```

Key rules:
- nil data = disconnect. ALWAYS call handleDisconnect.
- Recurse AFTER handling the message, not before.
- The 0.3s delay before FIRST receiveLoop call gives UI time to render.
- After that, recursion is immediate — no delays between messages.

---

## connectToHost Pattern (PROVEN)

1. Create NWConnection with `includePeerToPeer = true`
2. Set stateUpdateHandler BEFORE calling .start()
3. Call .start(queue: networkQueue)
4. 3-second timeout via DispatchQueue.main.asyncAfter — cancels if not .ready
5. On .ready:
   - Store connection as hostConnection
   - Set role = .player
   - Cancel browser
   - Send .join message
   - Start receiveLoop (after 0.3s delay)
6. On .failed/.cancelled:
   - Check hostConnection === connection (prevent stale callbacks)
   - Reset to solo
   - Increment reconnectAttempts
   - Restart browser

---

## handleDisconnect Pattern (PROVEN)

**Player side (host dropped):**
- Null hostConnection
- Reset to solo
- Increment reconnectAttempts
- Restart browser (for potential reconnection)

**Host side (player dropped):**
- Remove from connections array
- Remove from connectionNames, connectionDeviceIDs, connectedEndpoints
- Remove name from connectedPeers
- If all peers gone: start 6-second timeout, end session if nobody reconnects

---

## endGame Pattern (PROVEN)

1. Send .gameOver (or .sessionEnd) to ALL connections
2. Wait for send completion callbacks (countdown pattern)
3. THEN tear down — cancel listener, cancel all connections, clear all state
4. Restart passive listener (or browser in TheSeat's case)

DO NOT tear down connections before the message sends. The message won't arrive.

---

## Browser / Stale Bonjour Handling (PROVEN)

- `lastLeftHostName` stores the host name when player voluntarily leaves
- Browser skips any host matching that name (prevents auto-rejoin to stale entry)
- Block clears when: (a) host disappears from browse results, (b) resumeFromBackground
- `reconnectAttempts < 3` circuit breaker prevents infinite loops
- Browser only auto-connects when role == .solo AND hostConnection == nil AND !isConnectingToHost

---

## Delays Used (all asyncAfter)

| Delay | Purpose |
|-------|---------|
| 0.3s | After connection accepted — before receiveLoop. Gives UI render time. |
| 3.0s | connectToHost timeout. Cancel if not .ready. |
| 6.0s | Host auto-end after last player disconnects. |
| 3.0s | TheSeat-specific: After endSession, before restarting browser (Bonjour cache flush). |

---

## Key Differences: HCF vs TheSeat

| HCF | TheSeat |
|-----|---------|
| NSObject | @Observable |
| All queues .main | networkQueue (background) + DispatchQueue.main.async for state |
| Passive listener (always-on) | Browser always-on in solo |
| Auto-connects on browse | Shows toast, user taps Join |
| `Task { @MainActor in }` | `DispatchQueue.main.async` (avoids Task pile-up) |

---

## Rules for TheSeat Networking (DO NOT BREAK)

1. NEVER use `Task { @MainActor in }` in networking callbacks — use `DispatchQueue.main.async`
2. The receive loop recurse call (`receiveLoop`) MUST be inside the `DispatchQueue.main.async` block AFTER handleMessage
3. nil data in receive = disconnect. Always handle it.
4. 0.3s delay before first receiveLoop ONLY. Not between messages.
5. All NWConnection/NWBrowser/NWListener.start() use networkQueue, NOT .main
6. State mutations (role, toast, connectedPeers) happen ONLY in DispatchQueue.main.async
7. endSession() must send .sessionEnd and wait for delivery before teardown
8. After ending a session, delay browser restart by 3 seconds (stale Bonjour)
9. The 6-second auto-end timeout: if last player leaves and nobody reconnects, end session
10. hostConnection === connection check on .failed/.cancelled prevents stale callback processing
