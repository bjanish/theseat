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
- [x] Messages: join, question, currentQuestion, passTheSeat, youAreHost, newHost, sessionEnd, heartbeat
- [x] Toast system for connection events
- [x] Browser runs passively on solo screen, shows host name on Join button
- [x] Ghost connection timeout (3s — no .join received)
- [ ] Test host-to-player on two real phones (second session reconnect)
- [ ] Verify auto-reconnect after player resume from background
- [ ] Test without WiFi (AWDL peer-to-peer only)

---

## 3. Screens & UI Skeleton

- [x] Name entry: text field, persists UserDefaults, first launch only
- [x] Solo: seat glow + "THE SEAT" branding + Host/Join buttons
- [x] Solo: spotlight effect, Cinzel font, tagline on appear
- [x] Solo: "Join [host name]'s Session" button with gold glow when host detected
- [x] Host: card stack with gold border, Cinzel font, swipe left/right to cycle, tap to choose
- [x] Host: flourish decorations above and below cards
- [x] Host: "swipe to browse · tap to choose" instruction
- [x] Host: full-screen question display in Cinzel, tap to dismiss
- [x] Host: Pass button, End button in top bar
- [x] Player: text input with gold underline, 150-char counter, send button
- [x] Player: "Your question is in" + "Stay connected" after sending
- [x] Player: shared question display (Cinzel) when host selects a question
- [x] Player: Leave button
- [ ] Settings accessible from solo screen

---

## 4. Host Queue Behavior

- [x] FIFO array
- [x] Swipe left/right = cycle through questions (nothing deleted)
- [x] Tap = select (full-screen, sent as `.currentQuestion`)
- [x] Queue persists during session
- [x] No duplicate detection on question text
- [x] Host session stays live after last player leaves (host ends manually)

---

## 5. Player Input & Character Limit

- [x] 150 characters max
- [x] Counter shows remaining
- [x] Enforced client-side (stops accepting at 150)
- [x] Send disabled when empty
- [x] Light haptic on send
- [x] Field clears after send
- [x] ONE question per HOST — input locks after sending, resets on seat pass
- [x] After send: show "Your question is in" + "Stay connected" confirmation
- [ ] Confirmation modal before sending — player reviews question before committing
- [ ] Trim + reject empty whitespace

---

## 6. Visual Design

- [x] Dark UI: Color(white: 0.08) background with spotlight gradient
- [x] "THE SEAT" Cinzel font, tracked uppercase, gold tone, text shadow
- [x] Chair image with floor shadow, easter egg gold glow on tap
- [x] Full-screen question: Cinzel font, centered, tap to dismiss
- [x] "The Seat" watermark during full-screen display
- [x] Card stack with gold border, peek to the right
- [x] Flourish decorations (ornamental gold image) above and below cards
- [x] Gold glow on "Join" button when host detected

---

## 7. Audio & Haptics

- [ ] Question received (host): ping + light haptic
- [x] Question sent (player): light haptic
- [ ] Pass the Seat: medium haptic both sides
- [ ] Player connects: connection sound + medium haptic
- [ ] Question selected: light haptic
- [x] Audio session: `.playback` + `.mixWithOthers`
- [ ] Custom ping sound bundled (not card flip)
- [x] Easter egg: heavy haptic on chair tap

---

## 8. Pass the Seat

- [x] Host taps "Pass" → player list sheet
- [x] Tap name → `.passTheSeat` + `.youAreHost` sent
- [x] Target becomes host, original becomes player
- [x] Queue does NOT transfer (fresh start)
- [x] Connections stay alive
- [x] `.newHost(name:)` broadcast to all players
- [x] Player input resets on new host (hostRound counter)
- [x] Toast: "[Name] is in the seat" on seat pass
- [ ] Medium haptic both sides
- [ ] Test pass on real devices

---

## 9. Lifecycle

- [x] Host backgrounds → `.sessionEnd` → teardown
- [x] Player backgrounds → cancel connection + browser
- [x] Player resumes → restart browser, auto-reconnect
- [x] Host resumes → session gone, back to solo
- [x] "End Session" = same as backgrounding
- [x] Player returns to solo on host disconnect
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

- [ ] One-time $0.99 non-consumable unlock
- [ ] Gate hosting after 5 free sessions
- [ ] Session count increments when first player joins (not on tap)
- [ ] StoreKit 2 / StoreManager (@MainActor @Observable)
- [ ] Restore Purchase in Settings
- [ ] Paywall UI matches app theme (gold, dark, Cinzel)
- [ ] `paywallEnabled` flag behind `#if DEBUG` for testing

---

## 13. Solo Mode: Would You Answer?

- [ ] Random questions from curated pool
- [ ] Swipe right = "I'd answer that" → streak increments
- [ ] Swipe left = "Pass" → streak resets to 0
- [ ] Streak counter + best streak
- [ ] Question pool (100+ questions)
- [ ] Tap chair to start

---

## 12. Open Questions (decisions made)

- [x] No going back to previous questions — swipe cycles, nothing deleted
- [x] Players see current question (shared screen moment)
- [x] Host does NOT see who asked (full anonymity)
- [x] Empty queue: glow + "Waiting for questions..."
- [x] One question per host (not unlimited)

---

## Debug: Simulated Characters

- [x] Add simulated players behind `#if DEBUG` (Charlie, Lucy, Schroeder)
- [x] Appear in connectedPeers list and player count
- [x] Each sends one random question (staggered 2s/4s/6s)
- [x] Valid targets for "Pass the Seat"
- [x] Question pool: PG-13 funny/awkward questions
- [x] Production/Release builds: no simulated characters (behind `#if DEBUG`)
