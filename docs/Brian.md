# Brian Janish

## Who

- 60 years old. Been developing since 20 — 40 years of experience.
- Solo indie developer. Signs with his personal Apple ID (Personal Team). No separate dev team, no co-founders. Just him.
- Ships to App Store under his own name/account. Has at least one shipped app: **HighCard Flip** (HCF), which is his reference codebase for proven networking patterns.
- Currently building **The Seat** — an anonymous hot-seat Q&A party game using peer-to-peer local networking. Release target August 31, 2026.
- Has a **Spades** app specced out as his next project after The Seat ships. Also has **Under Oath** (anonymous verdict game) on the shelf.
- Tests on two real devices: **iPhone 16 Pro** and **iPhone 13 mini**.
- GitHub: `github.com/bjanish/theseat`
- Email domain: `bjanish.com` (support@bjanish.com for app feedback, privacy policy to be hosted at bjanish.com/privacy)
- Bundle ID pattern: `com.bjanish.*`
- Home directory: `/Users/brianjanish`
- macOS user, uses Xcode (currently Xcode 27 beta based on the objectVersion 110 steering rules).
- Central time zone (CDT).

## Working Style

- Types fast, makes typos — doesn't want them corrected, just understood.
- Trusts his instincts and is right. When he says something worked before, believe him.
- Wants honesty — no hedging, no false modesty, no over-qualifying.
- Doesn't want hand-holding or basic concepts explained.
- Spec order = build order. Each section done-done before moving on. Quality before speed.
- Wants proposals before code changes, but only needs to approve once per change — not on every file.
- Never done. Don't ask "are we done?" Don't suggest wrapping up or going to bed.
- Says "stop" and means it. Says "revert" and means exactly what he says.
- Encourages independent thinking — but wants ideas proposed before acting on them.
- Wants "Done." said only after actual code changes, so he knows to build.

## Technical Preferences

- SwiftUI + Network framework + AVFoundation stack
- `@MainActor @Observable` for session state
- All networking on `.main` queue (proven pattern from HCF)
- Explicit Info.plist (doesn't trust GENERATE_INFOPLIST_FILE)
- `#if DEBUG` for everything test-related — zero leakage in production binaries
- No MultipeerConnectivity (deprecated)
- Cinzel font family for display text, gold accent color (0.85, 0.70, 0.40)
- Dark UI aesthetic — elegant, not casino/cartoonish
- objectVersion 70 in pbxproj for Xcode Cloud compatibility
- Privacy-conscious: no logging in release builds, no information leakage

## Philosophy

- Problem-solving mindset: when stuck, compare against working code (HCF). Don't accept "it's the environment" if a reference app proves otherwise.
- The answer is always simpler than the symptoms suggest.
- There IS a solution. Always.
- Build products for in-room social energy — phones run the game, people do the talking.
