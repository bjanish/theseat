# The Seat — Build Checklist

Spec order = build order. Each section done-done before moving to the next.

---

## 1. Tech Stack & File Structure

- [x] SwiftUI + Network framework + AVFoundation
- [x] @MainActor @Observable SessionManager
- [x] SeatMessage in separate file
- [x] `#if DEBUG` for all test infrastructure
- [x] Bundle ID: com.bjanish.askme
- [x] App icon: ornate chair, dark background, gold tone, spotlight

---

## 2. Networking

- [x] NWBrowser + NWListener + NWConnection, `includePeerToPeer = true`
- [x] Service type: `_theseat._tcp`
- [x] Service name: `playerName-deviceID-host` or `playerName-deviceID`
- [x] 6-char UUID device ID in UserDefaults
- [x] Self-filter, endpoint dedup, device ID dedup
- [x] Connection timeout (3s), circuit breaker (3 attempts)
- [x] Host starts listener, accepts connections
- [x] Player browser finds `-host` service, auto-connects, sends `.join`
- [x] Same-name auto-suffix ("Brian 2")
- [x] Connection-to-name dictionary (not parallel arrays)
- [x] Messages: join, question, currentQuestion, passTheSeat, youAreHost, sessionEnd, heartbeat
- [ ] Test host-to-player connection on two real devices
- [ ] Verify auto-reconnect after player resume from background

---

## 3. Screens & UI Skeleton

- [x] Name entry: text field, persists UserDefaults, first launch only
- [x] Solo: seat glow + "THE SEAT" branding + Host/Join buttons
- [x] Host: question display, queue count, swipe left skip, swipe right show, end session, player count
- [x] Player: text input, send button, 150-char counter, "Connected to [host]", leave button
- [ ] Settings accessible from solo screen
- [ ] Solo ↔ Host toggle (spec says toggle pattern like HCF, currently using buttons)

---

## 4. Host Queue Behavior

- [x] FIFO array
- [x] Swipe left = skip (gone forever)
- [x] Swipe right/tap = select (full-screen, sent as `.currentQuestion`)
- [ ] No undo on skip — verify behavior
- [x] Queue persists during session
- [x] No duplicate detection on question text
- [ ] Test with multiple rapid questions

---

## 5. Player Input & Character Limit

- [x] 150 characters max
- [x] Counter shows remaining
- [x] Enforced client-side (stops accepting at 150)
- [x] Send disabled when empty
- [x] Light haptic on send
- [x] Field clears after send
- [ ] ONE question per player per session — input locks after sending
- [ ] After send: show "Your question is in" confirmation
- [ ] Confirmation modal before sending — player reviews question, can edit or confirm before committing
- [ ] Trim + reject empty whitespace

---

## 6. Visual Design

- [x] Dark UI: Color(white: 0.12) background
- [x] "THE SEAT" tracked uppercase, gold tone
- [x] Empty seat glow: breathing animation with chair icon
- [x] Full-screen question: large white text, centered, screenshot-friendly
- [x] "The Seat" watermark in corner during full-screen display
- [ ] Blue connection glow on player connect
- [ ] Glow goes away when questions arrive, returns when empty
- [ ] Queue count badge near question area
- [ ] Player screen polish: minimal, input is focus

---

## 7. Audio & Haptics

- [ ] Question received (host): ping + light haptic
- [ ] Question sent (player): light haptic
- [ ] Pass the Seat: medium haptic both sides
- [ ] Player connects: connection sound + medium haptic
- [ ] Question selected: light haptic
- [x] Audio session: `.playback` + `.mixWithOthers`
- [ ] Custom ping sound bundled (not card flip)

---

## 8. Pass the Seat

- [x] Host taps "Pass the Seat" → player list (skeleton)
- [x] Tap name → `.passTheSeat` + `.youAreHost` sent
- [x] Target becomes host, original becomes player
- [x] Queue does NOT transfer (fresh start)
- [x] Connections stay alive
- [ ] No confirmation dialog — verify
- [ ] Medium haptic both sides
- [ ] Broadcast "[Name] is in the seat" to all players (toast)
- [ ] All player screens update "Connected to [host]" with new host name
- [ ] Add `.newHost(name: String)` message type
- [ ] Test on real devices

---

## 9. Lifecycle

- [x] Host backgrounds → `.sessionEnd` → teardown
- [x] Player backgrounds → cancel connection + browser
- [x] Player resumes → restart browser, auto-reconnect
- [x] Host resumes → session gone, back to solo
- [x] "End Session" = same as backgrounding
- [ ] Idle timer disabled while active
- [ ] Test background/resume on real devices

---

## 10. Onboarding

- [x] 3 slides: hero, flow, control
- [x] TabView swipe pattern
- [x] Local network permission mention
- [ ] Polish slide content and visuals

---

## 11. Paywall

- [x] Ship v1.0 free — no paywall code needed

---

## 13. Solo Mode: Would You Answer?

- Random questions appear one at a time from a curated pool
- Swipe right = "I'd answer that" → streak increments
- Swipe left = "Pass" → streak resets to 0
- Streak counter visible (same 🔥 pattern as HCF Higher/Lower)
- Best streak persists via @AppStorage("bestStreak") — shown next to streak, invisible when 0
- Question pool: mix of funny, awkward, deep, absurd questions (100+ to start)
- Questions don't repeat until pool is exhausted, then reshuffles
- Tap the chair/glow to start — transitions from solo branding to game mode
- Light haptic on swipe
- Teaches the core mechanic: you're in the seat, deciding what to answer
- No timer, no pressure — play at your own pace
- Available in solo state only (hidden when hosting or connected as player)

---

## 12. Open Questions (decisions needed)

- [ ] No going back to previous questions (proposal: no)
- [ ] Players see current question? (specced but optional — currently implemented)
- [ ] Host sees who asked? (proposal: no, full anonymity — currently implemented as anonymous)
- [ ] Empty queue state (proposal: glow + "Waiting for questions..." — currently implemented)
- [ ] Multiple questions from same player (proposal: yes, no throttle — currently no restriction)

---

## Debug: Simulated Characters

- [ ] Add simulated players behind `#if DEBUG` (e.g., "Charlie", "Lucy", "Schroeder")
- [ ] Simulated players auto-join with name + fake device ID
- [ ] Appear in connectedPeers list and player count
- [ ] Send random questions on a timer (every few seconds)
- [ ] Valid targets for "Pass the Seat"
- [ ] Question pool: mix of funny/awkward/random questions for realistic testing
- [ ] Brian says "enable characters" → uncomment simulated players
- [ ] Brian says "disable characters" or "two phone mode" → comment them out
- [ ] Do NOT connect a second phone while simulated characters are enabled
- [ ] Production/Release builds: no simulated characters (behind `#if DEBUG`)
