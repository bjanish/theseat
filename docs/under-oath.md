# Under Oath

**Status:** On the shelf. Preserve this concept and visual direction; revisit only after The Seat ships and a stronger core game loop is defined.

## Product Premise

Under Oath is a nearby, multi-device social verdict experience.

One person is **Under Oath**. The other participants submit one anonymous binary verdict:

- **Guilty**
- **Not Guilty**

The person under oath receives the collective outcome, but must never see how any individual participant voted.

The dramatic engine is anonymous judgment, suspense before the reveal, and the social tension of receiving a verdict from the room.

## Essential Rules

- There are **no questions**, typed answers, truth-or-lie submissions, or liar-identification mechanics.
- Each participant's action is a binary **Guilty** or **Not Guilty** verdict.
- Individual verdict attribution is never shown to the person under oath.
- The reveal communicates the group result without mapping a verdict back to a person.
- The app is about judgment, not interrogation or anonymous Q&A.

## Core Round Shape

1. A person is placed Under Oath.
2. Nearby participants submit **Guilty** or **Not Guilty** anonymously.
3. Voting closes.
4. The collective verdict is revealed to the person under oath and the room.
5. A future round begins with the next person.

The exact start, close, and reveal controls remain product decisions to make during design.

## Why It Is Distinct From The Seat

| The Seat | Under Oath |
|---|---|
| Anonymous questions | Anonymous binary verdicts |
| A host selects a question and answers it | A person receives the room's collective judgment |
| Anonymity protects the asker | Anonymity protects the voter |
| The social moment is honesty and disclosure | The social moment is suspense and judgment |

The apps may reuse nearby-device networking patterns, but they are separate products with different player actions, outcomes, and emotional stakes.

## Visual Direction — Locked

### Home Screen

- Full-screen witness-box image: a faceless person in a black suit, seated at dark wood courtroom furniture, with their right hand raised in oath.
- No face visible.
- Palette: near-black, deep brown wood, warm amber hand highlights, restrained gold.
- The raised hand is the visual focal point and must remain unobstructed.
- Text and controls sit on their own dark translucent backplates so they stay readable without washing out the artwork.

### App Icon

- Tight crop of the raised hand, suit, and dark wood setting.
- Thin gold inset border.
- No text in the icon.
- The hand must read immediately at small Home Screen size.

The image prompt reference is in `docs/splash-image.md`.

## Future Technical Direction

Under Oath can reuse proven architecture patterns from The Seat after The Seat ships:

- SwiftUI app structure
- `@MainActor @Observable` session state
- Network framework peer-to-peer discovery and connections (`NWBrowser`, `NWListener`, `NWConnection`)
- Local-network onboarding and permission priming
- Toast, audio, haptic, settings, and build-checklist patterns

Reuse the engineering patterns deliberately, but keep Under Oath's message model, screens, state, and user flow separate from The Seat.

## Product Decisions Still Open

1. Who starts a round and chooses the person Under Oath?
2. Does every connected participant have to vote before the verdict can reveal?
3. Does the reveal show only **Guilty** / **Not Guilty**, or also a vote count or percentage?
4. How does a round close: host control, timed vote, or unanimous participation?
5. How does the next person take their turn?
6. What are the minimum and maximum player counts?
7. Is there any response or discussion state after the verdict, or does the app move directly to the next round?
8. What unique Bonjour service type and bundle ID will Under Oath use?
