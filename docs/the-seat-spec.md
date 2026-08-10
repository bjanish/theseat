# The Seat — Spec

## Summary
Anonymous hot seat Q&A. One person sits in "the seat" — everyone else connects and sends questions anonymously. The host picks which questions to answer out loud. Nobody knows who asked what.

## One Sentence Pitch
"Take the seat. Answer anything."

## Tagline
"Anonymously ask questions to the host."

## App Store Description (draft)
Take the seat. Answer anything.

One person sits in the hot seat — everyone else connects and fires anonymous questions from their phone. No accounts. No internet. Just you, your friends, and whatever you dare to ask.

The host picks which questions to answer out loud. Nobody knows who asked what.

## Build Philosophy
Spec order = build order. Each section is done-done before moving to the next. No "get it compiling fast then revisit" — each step produces something finished and correct. Quality before speed.

---

## 1. Tech Stack & File Structure

### Stack
- SwiftUI
- Network framework (NWBrowser + NWListener + NWConnection + peer-to-peer)
- No server, no accounts, no internet required
- AVFoundation for audio
- @MainActor @Observable SessionManager (single source of truth, same pattern as GameManager)
- Separate message file (SeatMessage.swift) to avoid main-actor isolation
- `#if DEBUG` for all test infrastructure

### File Structure
```
TheSeat/
├── TheSeatApp.swift          // @main, audio session, routing
├── SessionManager.swift      // networking + session state (@MainActor @Observable)
├── SeatMessage.swift         // message enum (Codable, separate file)
├── ContentView.swift         // main UI, role-based switching
├── HostView.swift            // queue display, question full-screen, pass button
├── PlayerView.swift          // text input, send, status
├── NameEntryView.swift       // first-launch name input
├── OnboardingView.swift      // 2-3 slide intro
├── SettingsView.swift        // name change, about, privacy policy
├── GlowView.swift            // reusable glow system (port from HCF)
└── Assets.xcassets/          // app icon, colors
```

### App Store Info
- **Name:** The Seat
- **Bundle ID:** com.bjanish.askme
- **App Store Connect:** Reserved
- **GitHub repo:** Set up

### App Icon
- An ornate chair angled slightly right on a dark background
- Elegant but subtle — not cartoonish
- Optional spotlight from above hitting the empty chair
- "The seat is waiting."

**AI generation prompts:**

Minimal/Clean:
```
A single ornate chair angled slightly to the right, centered on a pure black background. The chair is elegant and subtle — dark gold or muted bronze tone with fine decorative details. A soft spotlight cone from above illuminates the empty chair. Minimal, icon-style, no text, no floor, no shadows on ground. Square format, app icon style.
```

More dramatic:
```
An empty ornate throne-like chair angled slightly right, lit by a single dramatic spotlight from above on a dark black background. The chair is elegant with subtle carved details, muted gold color. The light creates a cone shape hitting only the chair. Dark, moody, mysterious atmosphere. Flat icon style, square format, centered composition, no text.
```

Ultra simple:
```
App icon: single ornate chair, dark background, subtle gold tone, angled right, soft spotlight from above. Minimalist, elegant, mysterious. No text, no floor, centered. Square 1024x1024.
```

---

## 2. Networking

### Architecture (port from HCF)
- Network framework: NWBrowser + NWListener + NWConnection
- `includePeerToPeer = true` (AWDL — works without WiFi)
- Service type: `_theseat._tcp`
- Service name format: `playerName-deviceID-host` (hosting) or `playerName-deviceID` (passive)
- Same device ID scheme (6-char UUID in UserDefaults)
- Same self-filter, endpoint dedup, device ID dedup
- Same background/resume lifecycle handling
- Same connection timeout (3s), circuit breaker (3 attempts)

### Connection Model
- Host: starts listener, accepts incoming connections
- Player: browser finds host's `-host` service, auto-connects, sends `.join`
- Same duplicate detection (device ID primary, endpoint secondary)
- Same same-name auto-suffix ("Brian 2")
- Host maintains connection-to-name dictionary (not parallel arrays)

### Message Types
```swift
enum SeatMessage: Codable, Sendable {
    case join(name: String, deviceID: String)
    case question(text: String)              // player → host
    case currentQuestion(text: String)       // host → all players (shared screen)
    case passTheSeat(toName: String)         // host → target player
    case youAreHost                          // host → new host (after pass)
    case sessionEnd                          // host → all (teardown)
    case heartbeat
}
```

---

## 3. Screens & UI Skeleton

### Name Entry (first launch only)
- Same pattern as HCF — text field, "What's your name?", persists in UserDefaults
- No account, no sign-in

### Home / Solo State
- Empty seat glow (breathing animation, like HCF crown glow)
- "THE SEAT" branding centered
- Toggle: Solo ↔ Host (same pattern as HCF's Solo ↔ Game toggle)
- In solo state the app just shows the branding + glow. No functionality until hosting or connecting.

### Host Screen
- Large question text area (center of screen, big readable font)
- Queue indicator: count of pending questions (e.g., "4 waiting")
- Swipe left to skip/dismiss a question
- Swipe right (or tap) to display it full-screen
- "Pass the Seat" button — transfers host to another player
- "End Session" — tears down all connections, returns to solo
- Connected player count shown (like HCF's player count)

### Player Screen
- Text input field (bottom of screen, keyboard-friendly)
- Send button
- Character counter (limit: 150 characters)
- Status: "Connected to [host name]" at top
- Optional: see the current question the host is displaying (shared screen moment — TBD)
- "Leave" button to disconnect

---

## 4. Host Queue Behavior

- Questions arrive in order, stored in an array
- Host sees the oldest unread question first (FIFO)
- Swipe left = skip (removed from queue, never shown full-screen)
- Swipe right or tap = select (displays full-screen, sent to all players as `.currentQuestion`)
- Skipped questions are gone — no undo
- Queue persists during session (not cleared between questions)
- No duplicate detection on question text (two people can ask the same thing)

---

## 5. Player Input & Character Limit

- 150 characters max per question
- Counter shows remaining characters as you type
- Enforced client-side (text field stops accepting input at 150)
- Send button disabled when field is empty
- Light haptic on send
- Field clears after send
- ONE question per HOST — input locks after sending. Resets when the seat passes to a new host.
- Confirmation modal before sending — player sees their question and can edit or confirm before committing. One shot means they need the chance to review.
- After send: show "Your question is in" confirmation, input disabled
- When `.newHost` is received, `hasAsked` resets and input opens again — fresh question for the new host
- Players stay connected through seat passes. No need to leave and rejoin.
- Player only leaves if they're done playing entirely.
- Short questions are funnier. Constraint breeds creativity. One shot raises the stakes.

---

## 6. Visual Design

- Dark UI (Color(white: 0.12) background, same as HCF)
- Branding: "THE SEAT" — tracked uppercase, gold tone (same family as HCF's crown gold)
- Empty seat glow: breathing animation around the question display area when queue is empty. Goes away on first question arrival. Returns when queue empties again.
- Question display (host full-screen mode): large, clean white text on dark background. Centered vertically. Screenshot-friendly.
- Subtle "The Seat" watermark in corner when question is displayed full-screen (for screenshots/recordings)
- Connection glow: blue pulse on player connect (same as HCF)
- Queue count: small badge or number near the question area
- Player screen: minimal — input field is the focus, everything else stays out of the way

---

## 7. Audio & Haptics

- **Question received** (host): subtle ping sound + light haptic. Plays through silent switch, doesn't interrupt music.
- **Question sent** (player): light haptic confirmation
- **Pass the Seat**: medium haptic on both sides
- **Player connects**: connection sound + medium haptic (same as HCF)
- **Question selected** (host taps/swipes to display): light haptic
- Audio session: `.playback` with `.mixWithOthers`
- Custom sounds bundled in app (find/create appropriate ping — not the card flip sound)

---

## 8. Pass the Seat

- Host taps "Pass the Seat" → sees list of connected players
- Taps a name → sends `.passTheSeat(toName:)` to that player
- That player receives `.youAreHost` → their UI transitions to host screen
- Original host becomes a player (text input + send)
- Queue does NOT transfer — new host starts with an empty queue (fresh start)
- All connections stay alive — no reconnection needed
- Pass is instant — no confirmation dialog
- Medium haptic on both sides when pass completes
- Broadcast "[Name] is in the seat" to all connected players (toast/announcement)
- All player screens update "Connected to [host]" with new host's name
- New message type: `.newHost(name: String)` sent to all players on pass

---

## 9. Lifecycle

- Host locks phone → `enterBackground()` → sends `.sessionEnd` → tears down connections
- Player backgrounds → cancels connection + browser + passive listener (same as HCF)
- Player resumes → restarts browser, auto-reconnects if host still active
- Host resumes → session is gone (they backgrounded = session over). Returns to solo state.
- "End Session" button does same thing as backgrounding: `.sessionEnd` → teardown → solo
- Idle timer disabled while hosting or connected as player

---

## 10. Onboarding

- Minimal. 2-3 slides max:
  1. "Take the seat. Answer anything." (hero — the chair icon/image)
  2. "Friends connect anonymously. Questions appear." (show the flow)
  3. "You pick what to answer." (host control)
- Same swipe TabView pattern as HCF
- Local network permission slide (required for peer-to-peer)

---

## 11. Paywall (TBD — ship free first)

- Ship v1.0 free. No paywall.
- Evaluate after launch whether to gate hosting sessions (same model as HCF) or add cosmetics.
- Decision deferred — don't want paywall friction on a brand new app that needs word-of-mouth growth.

---

## 12. Open Questions (need decisions before build)

1. Can the host go back to a previous question they already answered? (Proposal: no — keeps it moving forward, no dwelling)
2. Can players see the current question the host is reading? (shared screen moment vs private host screen — `.currentQuestion` message is specced but optional)
3. Does the host see who asked a question? (Proposal: no — full anonymity, even from the host)
4. What happens when the queue is empty? (Proposal: empty seat glow returns + "Waiting for questions..." text)
5. Multiple questions from same player — allowed? (Proposal: yes, no throttle)

---

## Concerns

### Moderation / Safety
- What if someone sends something truly vile? Host can skip, but is there a "block player" option to cut off a specific connection? Or is skip-and-ignore sufficient since it's anonymous friends-only?

### Queue Empty State After Activity
- First time: empty seat glow + "Waiting for questions..." — specced. But after the host has answered all questions and queue is empty again — same state? Or different messaging ("No more questions" vs "Waiting for questions")?

### Host Full-Screen Display vs Queue Awareness
- Can the host see the queue count while a question is displayed full-screen? Or is it truly full-screen with nothing else visible (better for screenshots but hides info)?

### Text Input Edge Cases
- Emoji: count as 1 character or more toward the 150 limit? (Swift `.count` treats them as 1, but visually they take more space)
- Newlines: allowed in questions? Multi-line display on host screen?
- Empty whitespace: can someone send just spaces? (Probably trim + reject empty)

### Disconnect Mid-Session
- If a player disconnects while the host is reading their question — does anything happen? (Probably nothing — question is already in queue, anonymity means sender identity doesn't matter)

### Settings
- What's in settings? Name change, privacy policy, "about" — same pattern as HCF? Rate app link? Version number?

### Accessibility
- Dynamic type on host question display? Big text needs to stay readable but not overflow on very long questions at larger accessibility text sizes.

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

## Reference: What's Different from HCF

| HCF | The Seat |
|-----|----------|
| Card flip (visual moment) | Text display (reading moment) |
| Synchronized reveal (everyone flips at once) | Async (questions arrive whenever) |
| Host controls timing (deal/countdown) | Host controls selection (pick from queue) |
| Short rounds (flip, result, next) | Continuous flow (questions keep coming) |
| Paywall gates multiplayer | Free at launch |
| Card back customization | No equivalent (yet) |
| Result glow (win/lose) | Empty seat glow (waiting state) |
| Game ends → solo | Session ends → solo |

---

## Post-Launch Ideas

### Hall of Fame
- Questions the host chose to answer get saved locally on the host's device
- Scrollable highlight reel of best questions from past sessions
- Shows date/session it came from
- No server — purely local persistence
- Could become a social sharing feature later (screenshot-friendly cards)

---

## Future App Ideas (same networking stack)

### Mexican Train Dominoes
- Public domain game, no licensing issues
- Same peer-to-peer architecture: host manages board state, players send moves
- Turn-based with shared state (trains, communal train, playable tiles)
- Richer message payload but same NWBrowser/NWListener/NWConnection stack

### Card Matching Game (Uno-style)
- Can't use Uno name/branding (Mattel licensing)
- Mechanic is public domain (Crazy Eights family)
- Match by color or number, draw if you can't, reverse/skip/wild
- Different art, different name, same networking
