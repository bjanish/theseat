# Lie Detector

**Status:** Concept locked. Build after The Seat ships.

## Core Concept

Host asks a question, everyone submits an answer (truth or lie). Host reads them aloud, group votes on who's lying. Same peer-to-peer networking as HCF/The Seat — no internet, no accounts, no setup.

## Why This Works

- Same proven anonymous submission mechanic
- Social deduction is inherently fun (Mafia, Werewolf, Among Us)
- Creates shouting matches and accusations — the group IS the game
- Reuses the entire networking layer from The Seat
- Low lift to build — different UI skin, same bones

## Tech

- Port networking layer from The Seat (NWBrowser + NWListener + NWConnection, includePeerToPeer)
- Service type: TBD
- Host/player roles, same architecture
- StoreKit 2 paywall (same pattern as The Seat)
- SwiftUI, no backend, pure Apple frameworks

## Flow

1. Host picks a question (or types one)
2. All players submit an answer — could be truth or a lie
3. Host reads answers aloud one by one
4. Group discusses / accuses
5. Everyone votes on who they think is lying
6. Reveal: who was actually lying

## Open Questions

1. Does the host also submit an answer?
2. Does every player HAVE to lie, or is it optional?
3. Scoring — points for fooling people? Points for catching liars?
4. Round structure — fixed rounds or host controls pacing?
5. Name — "Lie Detector" or "Polygraph" or something else?
6. Visual theme — TBD (dark, moody, interrogation room? polygraph aesthetic?)

## Reusable From The Seat

- SessionManager architecture (@MainActor @Observable)
- Network framework peer-to-peer (NWBrowser/NWListener/NWConnection)
- Toast system (per-screen, x/y positioning)
- Onboarding flow (slides + network permission prime)
- Settings view pattern
- Audio/haptic system (preloaded AVAudioPlayer)
- Build checklist HTML dashboard template
- Paywall (StoreKit 2 / StoreManager pattern)
