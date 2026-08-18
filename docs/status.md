## Last Session: August 17, 2026 (Sunday night/Monday morning)

### Current State
- App compiles and runs on real devices (iPhone 16 Pro + iPhone 13 mini)
- **Peer-to-peer AWDL: WORKING** — architecture flipped to match HighCard Flip pattern
- WiFi networking: WORKING
- Role switching (host↔player): WORKING
- All code committed and pushed to GitHub (github.com/bjanish/theseat)
- Latest tag: v0.5.0-architecture-flip
- Branch: main

### Architecture (NEW as of this session)
- **Host initiates connections TO players** (not the other way around)
- Player advertises `-ready` Bonjour service and accepts incoming TCP connections
- Host browses for `-ready` services and connects to them (with 3s retry timer)
- Player must tap "Join" before accepting (`wantsToJoin` gate)
- Keep-alive: `.heartbeat` sent every 2 seconds to prevent AWDL idle dormancy
- All networking on `.main` queue (matches HighCard Flip)
- Host still advertises `-host` service for UI discovery (Join button)

### What's Working
- Home screen: spotlight, chair, Cinzel font, "Take the Seat" / "Join [Name]" buttons
- Room presence: "THE ROOM IS GATHERING" capsule with peer dots and names
- Host screen: card stack with flourishes, swipe to cycle, tap to answer, full-screen display
- Player screen: text input, chair glow at 60%, confirmation modal, one question per host
- Pass the Seat: full flow
- Toast system with auto-dismiss
- Background/resume: scenePhase wired
- Onboarding: Cinzel headlines, gold dots, permission timing (3s delay on slide 5)
- Easter egg: gold glow on chair tap

### Known Issues / Edge Cases
- If AWDL fails consistently at a specific location, reboot the phone first (AWDL radio can get stuck)
- Rapid connect/disconnect debugging cycles can poison AWDL state — reboot fixes it
- `docs/cat-3d.html` and `docs/theseat-3d.html` are committed but scrapped — delete in next cleanup

### Remaining Work
- Audio/Haptics: pass haptic, connect sound, question-selected haptic, custom ping
- Pass the Seat: haptic both sides, test on real devices
- Lifecycle: idle timer disabled while active
- Paywall: StoreKit 2, $0.99, gate hosting after 5 sessions
- Pre-submission: privacy policy, screenshots, App Store description, compliance
