# Two Truths and a Lie — Product Concept

**Status:** Concept. Build after The Seat ships. Possibly before or instead of Spades depending on momentum.

**Working title:** Two Truths (or "Sworn" — ties into the oath/honesty theme)

**Product promise:** Turn the classic party game into a phone-powered experience where everyone votes anonymously, nobody can cheat, and the reveal is always chaos.

---

## 1. The Experience in One Sentence

One person writes two truths and a lie. Everyone else guesses which is the lie — anonymously. Then the truth comes out.

---

## 2. Why It Works

- **Everyone knows the game.** Zero explanation needed. People have played this since middle school.
- **The phone solves the cheating problem.** No more "wait, which one did you say was #2?" — it's on screen.
- **Anonymous voting removes social pressure.** You don't have to raise your hand and commit publicly. Just tap.
- **The reveal is the payoff.** Seeing who got fooled, who was confident, who was wrong — that's the social energy.
- **Fast rounds.** 2-3 minutes each. The game stays moving. Nobody's bored.
- **Everyone performs.** Unlike The Seat where only the host answers, here everyone takes a turn writing statements and fooling people.

---

## 3. Core Loop

1. **Someone is "it."** Their phone shows the statement entry screen.
2. **They write 3 statements.** Two true, one lie. Private — nobody sees until they submit.
3. **Statements broadcast to all players.** Displayed as three numbered cards on everyone's phone.
4. **Everyone votes.** Tap which one they think is the lie. Anonymous. Can't change after submitting.
5. **Votes close.** Either when everyone has voted, or host manually closes (handles AFK players).
6. **Reveal.** The lie is highlighted. Vote breakdown shows how many picked each option.
7. **Scoring.** Points for guessing correctly. Bonus points for the writer if they fooled the majority.
8. **Next person.** Rotate clockwise, or host picks, or random.

---

## 4. Scoring (Simple)

- **+1 point** for each voter who correctly identifies the lie
- **+1 point to the writer** for each voter they fooled
- Running score displayed between rounds
- No "game over" threshold — play as many rounds as the group wants, or set a target (first to 10)

---

## 5. Architecture Reuse from The Seat

| Component | Reuse | New |
|-----------|-------|-----|
| NWBrowser + NWListener + NWConnection | Same pattern | — |
| Host-initiated connections, `-ready` advertising | Same | — |
| Bonjour discovery, device ID, dedup | Same | — |
| Keep-alive heartbeat (2s) | Same | — |
| Length-prefixed JSON framing | Same | — |
| `@MainActor @Observable` session manager | Same pattern, new class | — |
| Onboarding + permission flow | Same | — |
| Toast system | Same | — |
| Name entry + UserDefaults | Same | — |
| Private state → host validates → broadcast | Same concept | New message types |
| — | — | Statement entry UI |
| — | — | Voting UI (3 options) |
| — | — | Reveal animation |
| — | — | Score tracking |
| — | — | Round rotation logic |

**Estimate:** 60-70% reuse. The networking layer is copy/adapt. The new work is UI for statement entry, voting, reveal, and scoring.

---

## 6. Message Protocol (Draft)

```swift
enum TwoTruthsMessage: Codable, Sendable {
    // Connection
    case join(name: String, deviceID: String)
    case welcome(hostName: String)
    case lobbyUpdate(players: [String])
    
    // Game flow
    case gameStarted
    case yourTurn                              // → person who's "it"
    case submitStatements(truths: [String], lie: String)  // it → host
    case statementsRevealed(statements: [String], writerName: String)  // host → all (shuffled)
    case submitVote(choiceIndex: Int)          // voter → host
    case voteProgress(count: Int, total: Int)  // host → all
    case reveal(lieIndex: Int, votes: [Int])   // host → all
    case scoreUpdate(scores: [String: Int])    // host → all
    case nextRound(writerName: String)         // host → all
    
    // Session
    case sessionEnd
    case heartbeat
}
```

**Key privacy requirement:** The host shuffles the 3 statements before broadcasting. The writer submits truths and lie separately; the host randomizes position so even packet inspection can't reveal the answer before the reveal.

---

## 7. Screens

### Lobby
- Host + joined players listed
- "Start Game" when 3+ players connected
- Same dark/gold aesthetic

### Your Turn (writer)
- "Write two truths and one lie."
- Three text fields (or swipeable cards)
- Label which two are truths and which is the lie
- Submit button → host shuffles and broadcasts

### Voting (everyone else)
- Three statement cards displayed
- Writer's name shown: "[Name]'s turn"
- Tap one to select, confirm to lock in vote
- After voting: "Waiting for others..." with vote progress (3/5 voted)

### Reveal
- All three statements shown
- The lie highlights (red border or strikethrough)
- Vote breakdown: "4 people said #1, 1 person said #3"
- Points awarded animation
- Brief pause, then next round

### Scoreboard
- Running scores between rounds
- Accessible anytime via a small button
- Shows per-round performance and total

---

## 8. Design Decisions to Make

1. **App name** — "Two Truths" is generic. Something with more personality? "Sworn"? "Liar"? "Bluff"?
2. **Minimum players** — 3 feels right (writer + 2 voters minimum)
3. **Maximum players** — same as The Seat (unlimited joiners?)
4. **Turn order** — host picks? Random? Clockwise? Volunteer?
5. **Timer on voting?** — probably not in v1, but maybe a gentle nudge after 30s
6. **Timer on writing?** — no. Let people think. The pressure is social, not mechanical.
7. **Can the host play?** — yes, they just can't vote on their own round
8. **Bundle ID and service type** — TBD
9. **Paywall model** — same as The Seat? $0.99, gate hosting after 5 sessions?

---

## 9. Why Before Spades?

- **Faster to build.** No rules engine, no complex state machine, no trick resolution. It's a submit/vote/reveal loop.
- **Same audience as The Seat.** Party game, in-room, friends, anonymity. Cross-promotion is natural.
- **Proves the catalog strategy.** Three apps in the store (HCF, The Seat, Two Truths) shows a pattern. People start checking "what else does this developer make?"
- **Lower risk.** If it doesn't catch on, you spent 1-2 weeks, not 2 months like Spades would require.

Spades is the deeper, more impressive build. But Two Truths gets another product in the store faster with proven networking and a universally known game.

---

## 10. Visual Direction

Own identity, distinct from The Seat's gold/Cinzel look.

**App icon — DECIDED** (file: `docs/fingerprint_icon_1024.png`): A single fingerprint on a near-black rounded-square background. Most of the ridges glow blue; a wedge on the right side bleeds into orange, with a subtle magenta seam where the two colors meet. The metaphor: a fingerprint is identity/truth, and the orange section is the part that's false — the lie hidden inside the truth. Bold single shape that survives shrinking to home-screen size.

**Marketing hero image:** Three fingerprints side by side — two blue (matching), one orange (the odd one out = the lie). Gorgeous at full size, communicates the game instantly, but too detailed for the actual app icon. Use for the landing page / App Store feature graphic, not the icon.

**Color language:**
- Blue = truth / identity
- Orange = the lie / deception
- Neon-on-black glow aesthetic — eye-catching in a sea of flat icons, still feels premium/dark like The Seat's family without copying the gold

**To verify:** at smallest icon size (~40px Settings/Spotlight), confirm the orange section still reads as clearly separate from the blue.

---

## 11. Tagline Ideas

- "Fool the room."
- "Two truths. One lie. Everyone votes."
- "How well do your friends really know you?"
- "Lie to your friends. Anonymously."

---

## 12. Competitive Note (Aug 27)

There are existing apps in this space (e.g. "2 Truths" and variants). Not a blocker — existing apps prove there's an audience. Our edge is the same as The Seat's:

- **Truly local** — no internet, no cellular. Works camping, cabin, anywhere with no signal. Most competitors are single-device pass-and-play or require WiFi/accounts.
- **Anonymous voting** — nobody sees who guessed what until the reveal.
- **Everyone on their own phone** — no passing one device around.
- **Fast, premium, polished** — the neon fingerprint identity already sets it apart visually.

**Name — DECIDED: "Two Truths."** Registered with Apple. The dropped "and a lie" is intentional — the incomplete phrase is a curiosity hook; anyone who knows the game finishes the sentence themselves, and once you open the app the lie is self-evident. Name is locked; no alternatives under consideration.
