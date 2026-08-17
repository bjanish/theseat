## Last Session: August 16, 2026 (Sunday)

### Current State
- App compiles and runs on real devices (iPhone 16 Pro + iPhone 13 mini)
- Networking works phone-to-phone (host/join/question/pass/end flow)
- Room presence works: phones see each other before hosting
- Background/resume lifecycle wired via scenePhase — tested and confirmed
- All code committed and pushed to GitHub (github.com/bjanish/theseat)
- Latest tag: v0.4.5-lifecycle
- Checklist: 105/127 done (83%), 22 remaining

### What's Working
- Home screen: spotlight, chair, Cinzel font, "Take the Seat" / "Join [Name]" buttons
- Room presence: "THE ROOM IS GATHERING" capsule with peer dots and names
- Host screen: card stack with flourishes, swipe to cycle, tap to answer, full-screen display
- Host empty state: "Invite your friends to open **The Seat**" when alone, "Waiting for questions..." when peers nearby
- Player screen: text input, confirmation modal ("Send this?" / Go back / Send), one question per host
- Pass the Seat: full flow (.newHost broadcast, player input resets)
- .welcome(hostName:) message corrects stale Bonjour-cached host name on join
- Toast system with auto-dismiss (showToast method)
- Background/resume: scenePhase wired, browser/listener restart on foreground
- Simulated characters (Charlie, Lucy, Schroeder) — currently disabled, easily re-enabled
- Easter egg: gold glow on chair tap
- Build checklist HTML dashboard

### Known Issues / Edge Cases
- Asymmetric Bonjour discovery between two real phones (rare, device-specific)
- Name change in Settings doesn't propagate to ready listener until app restart
- Simulator Bonjour can be flaky (stale cache, delayed discovery)
- `nw_listener_socket_inbox_create_socket setsockopt SO_NECP_LISTENUUID failed` seen on iPhone 16 Pro (OS-level, not our code)

### Architecture Notes
- SessionManager: @MainActor @Observable, networking on background DispatchQueue
- Receive loop uses DispatchQueue.main.async (NOT Task { @MainActor in })
- 0.3s delay before receiveLoop starts (gives UI render time)
- scenePhase observer in TheSeatApp.swift calls enterBackground/resumeFromBackground
- SeatMessage protocol: join, welcome, question, currentQuestion, passTheSeat, youAreHost, newHost, sessionEnd, heartbeat
- Room presence: solo phones advertise `-ready`, browse for `-ready` and `-host` services
- Host sends .welcome(hostName:) after accepting .join to correct stale names
- peersWereNearbyAtHostStart flag controls invite-vs-waiting empty state
- All debug logging behind #if DEBUG with prefixes: [SESSION], [HOST], [BROWSER], [BROWSE], [CONNECT], [RECV], [DISCONNECT], [READY], [PLAYER], [CHARACTER]

### Remaining Checklist Items (22)
- Networking: real-phone test (reconnect), AWDL-only test
- Audio/Haptics: pass haptic, connect sound, question-selected haptic, custom ping
- Pass the Seat: haptic both sides, test on real devices
- Lifecycle: idle timer disabled while active
- Onboarding: polish slide content
- Paywall: all 7 items (StoreKit 2, gate hosting, UI, restore, etc.)
- Pre-submission: privacy policy, screenshots, description, compliance

### Other Projects Documented
- docs/spades.md — Full pre-build specification for 4-player Spades app
- docs/under-oath.md — Shelved concept (on the shelf, not active)
