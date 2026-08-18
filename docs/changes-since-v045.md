# Changes Since v0.4.5-lifecycle (to re-add one by one)

## 1. Player Chair on Question Screen (PlayerView.swift)
- GlowView at 60% opacity centered on player screen
- Hides when host selects a question (replaced by question text)

## 2. Ack System — Detection Only (SessionManager.swift + SeatMessage.swift + PlayerView.swift)
- New message: `.questionReceived`
- Host sends `.questionReceived` back after receiving a question
- Player waits 5s for ack; if no ack, sets `questionDeliveryFailed = true`
- PlayerView observes `questionDeliveryFailed` → resets input, shows toast: "Couldn't deliver — try again.\nReboot if it persists" (5s duration, y: 0.3)
- `pendingQuestionText` / `ackTimeoutID` / `questionDeliveryFailed` cleared in leaveSession, tearDown, and .failed/.cancelled

## 3. Toast Position Changes (SessionManager.swift)
- "Connected" / "[host] is in The Seat" toast → y: 0.3
- "[Name] is in The Seat" (seat pass) → y: 0.3

## 4. Host-Side Stale Connection Replacement (SessionManager.swift)
- When `.join` arrives from a device ID already registered, replace the old stale connection instead of rejecting the new one
- Prevents lockout when player reconnects after a dead AWDL path

## 5. Keep-Alive Timer (SessionManager.swift)
- Sends `.heartbeat` every 4s from both host and player
- Fire-and-forget: no disconnect logic on failure
- Purpose: keep AWDL radio link from going dormant between messages
- Started on host startHosting() and player .ready
- Stopped on leaveSession, enterBackground, handleDisconnect, tearDown, .failed/.cancelled

## 6. Network Queue Change (SessionManager.swift)
- Changed `networkQueue` from background DispatchQueue to `.main`
- Matches HighCard's working pattern

## 7. Onboarding Permission Timing Fix (SessionManager.swift + OnboardingView.swift)
- `resumeFromBackground()` now checks `UserDefaults.standard.bool(forKey: "hasSeenOnboarding")` before calling `startBrowser()`
- OnboardingView triggers `startBrowser()` only on slide 5 after a 3-second delay
- "Get Started" button disabled for 3 seconds on last slide

## 8. Onboarding Polish (OnboardingView.swift + HowToPlayView.swift)
- Cinzel-Regular font on all slide headlines
- Gold page indicator dots via UIPageControl.appearance()
- `.multilineTextAlignment(.center)` on "Friends connect anonymously"
- Removed stray icon offsets (y: 1, y: -5, y: -9)
- HowToPlayView: increased "Done" button padding to 24pt

## 9. Steering/Convention Updates (.kiro/steering/conventions.md)
- "Say Done. only after code changes"
- "Propose before changes — once per approved change"
- "build-checklist.md and .html are ONE unit"
- "FIRST DEBUG STEP: reboot phone if AWDL fails"
- SessionStart hook: remind-propose-before-changes

## 10. Toast Centering (ToastView.swift)
- Added `.multilineTextAlignment(.center)` to toast text
