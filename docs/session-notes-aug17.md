# Session Notes — August 17, 2026 (Sunday night into Monday morning)

## Major Achievement: Architecture Flip (v0.5.0-architecture-flip)

Peer-to-peer AWDL delivery was completely broken. After hours of debugging, the fix was reversing the connection direction to match HighCard Flip's proven pattern:

**Old architecture (broken for P2P):**
- Player discovers host's `-host` service
- Player initiates TCP connection TO host
- AWDL would buffer/drop data sent after idle (typing delay)

**New architecture (working):**
- Host discovers player's `-ready` service
- Host initiates TCP connection TO player's listener
- Player accepts incoming connection, sends `.join`
- Keep-alive (.heartbeat every 2s) prevents AWDL idle dormancy
- All networking on `.main` queue (matches HCF)

### Key Design Decisions
- `wantsToJoin` gate: player must tap Join before accepting incoming host connection (prevents auto-join)
- Host retry timer: re-processes browse results every 3s so host retries connecting after player taps Join
- `leaveSession()` stops ready listener for 5s to prevent immediate auto-rejoin
- Host still advertises `-host` Bonjour service for UI discovery (Join button shows host name)
- Browser uses `NWParameters()` (empty) for discovery, `NWParameters.tcp` only for actual connections

### What Was Removed
- Ack system (`.questionReceived` message, timeout, `questionDeliveryFailed`) — unnecessary with working P2P
- Auto-reconnect logic — caused ghost connections and stale question resends
- Background `networkQueue` — replaced with `.main` queue matching HCF
- `TCP_NODELAY` experiment — didn't help

### What Was Kept
- Keep-alive timer (2s `.heartbeat`) — essential for preventing AWDL idle dormancy
- Host-side stale connection replacement on `.join` (device ID already registered → replace old connection)

## Other Changes This Session

### Onboarding Polish (OnboardingView.swift + HowToPlayView.swift)
- Cinzel-Regular font on all slide headlines (not Cinzel-Bold — only the variable font is registered)
- Gold page indicator dots via `UIPageControl.appearance()` (`.tint()` doesn't work on page-style TabView)
- `.multilineTextAlignment(.center)` on "Friends connect anonymously"
- Removed stray icon offsets (y: 1, y: -5, y: -9) for consistent spacing
- HowToPlayView: "Done" button padding increased to 24pt

### Onboarding Permission Timing Fix
- `resumeFromBackground()` checks `UserDefaults.standard.bool(forKey: "hasSeenOnboarding")` before calling `startBrowser()` — prevents network permission popup firing on first launch before onboarding
- OnboardingView triggers `startBrowser()` only on slide 5 (index 4) after a 3-second delay
- "Get Started" button disabled for 3 seconds on last slide so user reads the WiFi permission primer

### Player Screen
- GlowView (chair) at 60% opacity centered on player screen
- Hides when host selects a question (replaced by question text)

### Toast Changes
- "Connected" / "[host] is in The Seat" → y: 0.3
- "[Name] is in The Seat" (seat pass) → y: 0.3
- ToastView: added `.multilineTextAlignment(.center)`

### Steering File Updates (.kiro/steering/conventions.md)
- "Say Done. only after code changes"
- "Propose before changes — once per approved change, don't re-ask every file"
- "build-checklist.md and .html are ONE unit — never edited separately"
- "FIRST DEBUG STEP: reboot phone if AWDL fails"
- "Always be honest with Brian"
- SessionStart hook: remind-propose-before-changes

## Current State
- Tag: `v0.5.0-architecture-flip`
- Branch: `main` (up to date with origin)
- Peer-to-peer: WORKING (tested at home, both phones off WiFi)
- WiFi: WORKING
- Role switching: WORKING
- All onboarding/UI polish: APPLIED

## Known Issues
- Two deleted files locally (`docs/theseat-3d.html`, `docs/cat-3d.html`) — intentionally scrapped, not committed as deletions yet
- `docs/cat-3d.html` still exists in the commit but Brian doesn't want it — can be removed in next commit

## Key Lessons Learned This Session
- AWDL peer-to-peer requires the HOST to initiate connections, not the player — matching HCF's architecture
- A 2-second keep-alive is essential to prevent AWDL radio from going dormant during idle periods (typing time)
- Networking on `.main` queue works fine for this app — the "must use background queue" rule was wrong for this use case
- Auto-reconnect/auto-resend logic is dangerous — causes ghost connections, stale state leaking across sessions
- The ack timeout system (detection-only) was declaring failure before AWDL finished buffered delivery — removing it was the right call
- `Cinzel-Bold` doesn't resolve as a font name — only `Cinzel-Regular` works with the variable font file registered in Info.plist
- `.tint()` on page-style TabView doesn't color the dots — must use `UIPageControl.appearance()`
- `scenePhase` fires `.active` on first launch (not just resume) — `resumeFromBackground` needs onboarding gate

## Remaining Checklist Items (from build-checklist.md)
- Networking: real-phone test (reconnect), AWDL-only test ← AWDL NOW WORKING
- Audio/Haptics: pass haptic, connect sound, question-selected haptic, custom ping
- Pass the Seat: haptic both sides, test on real devices
- Lifecycle: idle timer disabled while active
- Paywall: all 7 items (StoreKit 2, gate hosting, UI, restore, etc.)
- Pre-submission: privacy policy, screenshots, description, compliance
