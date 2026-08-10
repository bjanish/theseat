# Project Conventions

- IMPORTANT: If there has been at least 12 hours between messages, run `date` in the terminal to check the current time. Do this BEFORE responding. Reset all time awareness to the result of the `date` command — do not rely on system-injected dates or previous assumptions.
- Always say "Done." when finished with a task so the user knows to run the build.
- When adding to build-checklist.md, ALWAYS update build-checklist.html to match.
- NEVER commit or push unless Brian explicitly asks.
- NEVER make code changes without Brian's go-ahead. Propose first, wait for approval.
- NEVER revert code without Brian's explicit permission. ASK FIRST every time.
- Do NOT go rogue — only do what Brian asks. No extra changes, no "improvements" he didn't request.
- If Brian says "stop," stop immediately.
- If Brian says "revert," revert exactly what he says — don't second-guess or keep parts.
- When Brian says "document this exactly" — use his exact words verbatim. Do not reformat, restructure, or rephrase.
- Brian occasionally types fast and makes typos — don't correct them, just understand intent.
- Brian is 60, has been developing since 20 (40 years). Don't explain basic concepts or hand-hold.
- Brian uses two iPhones for testing (iPhone 16 Pro + iPhone 13 mini).
- Never suggest Brian go to bed, rest, wrap up, or end the session.
- Never ask "are we done?" — Brian is never done with anything. Just ask "what's next?" or wait.
- Spec order = build order. Each section is done-done before moving to the next. No "get it compiling fast then revisit" — each step produces something finished and correct. Quality before speed.

# Signing

- Brian uses his personal Apple ID for signing (Personal Team in Xcode → Signing & Capabilities). Same account as HighCard. No separate dev team — just him.

# Architecture

- Networking: Network framework (NWBrowser + NWListener + NWConnection) with `includePeerToPeer = true`
- MultipeerConnectivity is deprecated — do NOT use it
- Session state: SessionManager (@MainActor @Observable) — single source of truth
- UI: ContentView routes to NameEntryView, OnboardingView, or role-based views (solo/host/player)
- Message encoding: SeatMessage enum in separate file (SeatMessage.swift) to avoid main-actor isolation issues
- Audio: .playback with .mixWithOthers — plays through silent switch, doesn't interrupt music
- Service type: `_theseat._tcp`
- Bundle ID: `com.bjanish.askme`
- Display name: "The Seat"
- iOS deployment target: 17.0
- Swift version: 5.0
- objectVersion: 70 (NOT 110 — Xcode Cloud requires 70)

# Key Lessons (do NOT repeat)

- All networking (listener, browser, connections) MUST run on background DispatchQueues — NOT `.main`. Running on `.main` causes the UI to freeze/become unresponsive. Callbacks hop to `@MainActor` via `Task` for state updates only.
- Connection receive loop (`startReceiving`) must start AFTER a 0.3s delay once connected — gives the UI time to render the Player screen before the receive loop starts competing for main thread time. Without this delay, the Player screen is unresponsive for several seconds after joining.
- `@Observable` networking properties that aren't `Hashable` (like NWConnection) must use `@ObservationIgnored` and `ObjectIdentifier` as dictionary keys.
- `AVAudioSession.setActive()` blocks the main thread — must run in `Task.detached`, never in init or onAppear synchronously.
- Info.plist font registration key is `UIAppFonts` (NOT `UIFonts`). `UIFonts` is what Xcode uses internally but it's not the actual plist key.
- `GENERATE_INFOPLIST_FILE = YES` is unreliable for NSBonjourServices and NSLocalNetworkUsageDescription — use an explicit Info.plist file instead.
- Simulator cannot do local network browsing (NoAuth error) — test networking on real devices only.
- iOS first-time keyboard load is slow (~1-2s) after fresh install — this is an Apple issue, not a code bug.
