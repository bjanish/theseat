# Ship Blockers & Remaining Work

## Must-Have for Ship

- [ ] Confirmation modal before sending question (player reviews before committing)
- [ ] Trim + reject empty whitespace on questions
- [ ] Idle timer disabled while hosting or connected as player
- [ ] Settings screen (name change, privacy policy, about, version, restore purchase)
- [ ] Paywall: $0.99 unlock, gate hosting after 5 free sessions, StoreKit 2
- [ ] Test on two real phones: second session reconnect, pass the seat, background/resume
- [ ] Test without WiFi (AWDL peer-to-peer only)

## Audio & Haptics

- [ ] Question received (host): ping + light haptic
- [ ] Pass the Seat: medium haptic both sides
- [ ] Player connects: connection sound + medium haptic
- [ ] Question selected (tap card): light haptic
- [ ] Custom ping sound bundled in app

## Polish

- [ ] Player screen polish (minimal, input is focus)
- [ ] Onboarding slide visuals

## Post-Launch (not blocking ship)

- [ ] Solo mode: "Would You Answer?" game
- [ ] Hall of Fame (save answered questions locally)

## Pre-Ship Refactoring (before App Store submission)

- [ ] Remove dead `announcedHosts` code (declared but no longer used)
- [ ] Simplify `wantsToJoin` flow — connect directly from cached endpoint on Join tap
- [ ] Fix endpoint dedup for IPv6 (current `:` split breaks on IPv6 addresses)
- [ ] endSession() send-completion counter (HCF pattern) instead of 0.1s delay
- [ ] Remove ghost connection timeout log noise
