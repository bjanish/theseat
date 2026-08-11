# Project Status — The Seat

## Last Session: August 9, 2026 (Sunday)

### Current State
- App compiles and runs on real devices (iPhone 16 Pro + iPhone 13 mini)
- Networking works phone-to-phone (host/join/question/pass/end flow)
- All code committed and pushed to GitHub (github.com/bjanish/theseat)
- Latest tag: v0.2-stable
- Latest commit: dashboard styling + favicon

### What's Working
- Home screen: spotlight, chair, Cinzel font, "Take the Seat" / "Join [Name]" buttons
- Host screen: card stack with flourishes, swipe to cycle, tap to answer, full-screen display
- Player screen: text input, one question per host, "Your question is in", shared question display
- Pass the Seat: full flow (host picks player, .newHost broadcast, player input resets)
- Toast system with auto-dismiss (showToast method)
- Simulated characters (Charlie, Lucy, Schroeder) — one question each, #if DEBUG
- Easter egg: gold glow on chair tap
- Browser passively detects hosts, button lights up with host name
- Host button disabled when someone else is hosting ("[Name] is in the seat")
- Build checklist HTML dashboard with shimmer, stats, chair icon, easter egg on title

### Known Issues / Edge Cases
- Second session reconnect sometimes fails (stale Bonjour cache)
- Simulator networking is unreliable (NoAuth) — test on real phones only
- Autocorrect lowercases first letter sometimes (disabled autocorrect as workaround)
- Toast positioning tight on iPhone 13 mini (reduced padding to 10pt)
- AWDL duplicate connections on second hosting (ghost timeout + endpoint dedup handles it)

### Ship Blockers (docs/ship-blockers.md)
- Confirmation modal before sending question
- Trim + reject empty whitespace
- Idle timer disabled while active
- Settings screen (name change, privacy, about, restore purchase)
- Paywall: $0.99 unlock after 5 free sessions (StoreKit 2)
- Test on two phones: reconnect, pass, background/resume
- Test without WiFi (AWDL)
- Haptics (question received, pass, connect, question selected)
- Custom ping sound

### Architecture Notes
- SessionManager: @MainActor @Observable, networking on background DispatchQueue
- Receive loop uses DispatchQueue.main.async (NOT Task { @MainActor in } — causes freezes)
- 0.3s delay before receiveLoop starts (gives UI render time)
- didSet doesn't work with @Observable — use showToast() method pattern instead
- All networking patterns documented in docs/networking-reference.md
- Steering conventions at .kiro/steering/conventions.md

### Files Modified This Session
- SessionManager.swift (full rewrite, toast system, simulated characters, host detection)
- ContentView.swift (button language, disabled states, gold glow, tagline)
- HostView.swift (card stack, flourishes, swipe gestures, pass button, instructions)
- PlayerView.swift (one question per host, shared question Cinzel, stay connected message)
- GlowView.swift (easter egg, chair image)
- ToastView.swift (auto-dismiss via showToast, positioning)
- SeatMessage.swift (added .newHost)
- Info.plist (NSBonjourServices, UIAppFonts)
- .kiro/steering/conventions.md (key lessons, build checklist rule)
- docs/ (spec, checklist md+html, networking reference, ship blockers, status)
