# Spades — Product & Build Specification

**Status:** Pre-build specification. Separate app; build after The Seat reaches its shipping point.

**Working title:** Spades

**Product promise:** Four friends in the same room can start a real, private-hand game of team Spades on their phones in under a minute—no accounts, Internet, room codes, physical deck, or card holders.

---

## 1. Product Definition

Spades is a four-player, two-team, local-network trick-taking card game. One phone hosts the session and acts as the authoritative dealer and rules engine. Three nearby phones join as players.

Every player sees their own 13-card hand only. The shared table, bids once revealed, trick history, turn state, round scores, and game result are synchronized to all four phones. The host validates every bid and card play before changing game state.

### The experience in one sentence

**Sit down with three people, join the same game nearby, play honest Spades with private hands, and let the phones handle the deal, rules, score, and bags.**

### Product pillars

1. **A real game of Spades.** Rules must be dependable enough that experienced Spades players trust the app.
2. **No setup friction.** Nearby discovery, a four-slot lobby, and a fast start.
3. **Private by design.** A player’s hand never appears on another player’s device.
4. **The host is the referee.** Clients request actions; the host validates and publishes the resulting state.
5. **In-room social energy.** The phones run the game while the people talk, partner up, trash talk, and react in person.

---

## 2. Relationship to The Seat

Spades is a separate app and a different product. It will reuse proven Apple Network framework patterns from The Seat/HCF, but it must not inherit Q&A state, seat-passing behavior, or The Seat’s message model.

| Reuse from The Seat | New for Spades |
|---|---|
| `NWBrowser` + `NWListener` + `NWConnection` peer-to-peer transport | Card, deck, bid, trick, turn, and score engines |
| Background networking queue + main-actor UI state | Host-authoritative private/public game state |
| Bonjour discovery, device identity, connection/endpoint de-duplication | Four-player lobby and fixed partnerships |
| Length-prefixed Codable message framing | Spades-specific message protocol |
| Local-network onboarding and permission priming | Private hand, table, bid, and score screens |
| Toast, settings, audio/haptic, and checklist patterns | Card interactions and game-specific audio/haptics |

The codebase should have its own `SpadesSessionManager`, `SpadesMessage`, game models, and service type. Do not copy `SessionManager` wholesale.

---

## 3. V1 Scope

### Included

- Exactly four connected players
- Two fixed teams of two
- Standard 52-card deck
- 13 cards dealt to every player
- Standard Spades trump/follow-suit play
- Standard bidding, including Nil
- Team scoring, bags, sets, and 500-point game end
- Host-selected teams in the lobby
- Local peer-to-peer play only
- Private hands, shared trick table, scores, and round results
- Host authority for shuffle, deal, bids, legal plays, trick resolution, and scoring
- Rejoin window for a temporarily disconnected non-host player **after the disconnect policy is finalized**

### Explicitly not V1

- Internet play, matchmaking, accounts, or backend
- More or fewer than four players
- Spectators
- AI players or AI takeover
- Jokers variant
- Blind Nil
- House-rule configuration
- Rankings, achievements, chat, recordings, or saved game history
- Fancy card-deal animations before the core game is solid
- StoreKit/paywall work until its pattern is proven in a shipped app

---

## 4. V1 Decisions: Locked vs. Still Needing Brian’s Call

### Current baseline from the existing concept

- Four players, two teams
- Host is the dealer and authoritative game engine
- Host chooses teams after all players join
- Standard deck; no jokers
- Spades are trump
- Nil is available; Blind Nil is not in v1
- Ten bags produce a 100-point penalty
- Game target is 500 points
- Card deal is instantaneous in v1
- Every hand remains private to its owner

### Build gate: decisions that must be settled before networking/gameplay code

1. **Disconnect policy.** Recommended v1: pause the session for a short rejoin window for a non-host player; if the same device does not return, end the game rather than use AI or attempt a partial round. A host disconnect ends the session in v1.
2. **Rejoin window duration.** Recommended: 60 seconds.
3. **Final app name and bundle identifier.** “Spades” is only a working title.
4. **Bonjour service type.** Use a distinct short type, for example `_spades._tcp`, once the app identifier is settled.

No code should silently decide these four items.

---

## 5. Game Rules Contract

The host rules engine is the single source of truth. Client UI may pre-highlight legal actions for clarity, but the host always validates the submitted action independently.

### 5.1 Players and teams

- There are exactly four seats: North, East, South, West.
- Partners sit opposite each other: North/South vs. East/West.
- The lobby can display player names, but seat orientation must be consistent for all devices.
- The host selects which two players form each team before the first deal.
- The host may be in either team.

### 5.2 Deck and rank order

- Use one standard 52-card deck: Clubs, Diamonds, Hearts, Spades.
- Each suit ranks low to high: 2, 3, 4, 5, 6, 7, 8, 9, 10, Jack, Queen, King, Ace.
- Spades are always trump.
- At the start of each round, the host performs one random shuffle and deals 13 cards to each player.

### 5.3 Bidding

- Bids are integers from **0 through 13**. A bid of 0 is Nil.
- Bidding begins with the player to the host’s left and proceeds clockwise.
- A player’s bid remains private until all four players have submitted.
- When the fourth bid arrives, the host reveals all bids simultaneously to every device.
- Team contract = the sum of both partners’ bids. Nil contributes 0 to the team contract.
- No bid time limit in v1.

### 5.4 Playing a trick

- The player to the host’s left leads the first trick of the round.
- The winner of each trick leads the next trick.
- A player who holds one or more cards in the led suit must play a card in that suit.
- A player void in the led suit may play any card, including a spade.
- A spade cannot lead a trick until Spades are broken—meaning a spade has been played on a previous non-spade-led trick—unless the leader holds only spades.
- The host rejects any card play that violates follow-suit or the Spades-broken rule.
- The highest card in the led suit wins, unless one or more spades are played; then the highest spade wins.
- The trick winner receives the trick, becomes the leader, and the host advances turn state.
- A round contains exactly 13 tricks.

### 5.5 Nil

- Nil is a bid of 0.
- A Nil bidder who takes no tricks earns **+100** points for their team.
- A Nil bidder who takes one or more tricks costs their team **−100** points.
- Tricks taken by a Nil bidder still count in the team’s total tricks and may become bags if the team makes its contract.
- Blind Nil is not in v1.

### 5.6 Team scoring

At the end of 13 tricks, score each team independently:

1. If team tricks are at least the team contract, award `contract × 10` points.
2. Each trick above the contract is one bag and awards +1 point.
3. If team tricks are below the team contract, subtract `contract × 10` points.
4. Apply each partner’s Nil result (+100 or −100) in addition to the team-contract result.
5. Add earned bags to that team’s running bag total.
6. Each time a team reaches 10 bags, subtract 100 points and remove 10 bags from its running bag total. Preserve any remainder bags.

Examples:

- Team bids 4 and takes 6: `+40` plus 2 bags = `+42`.
- Team bids 5 and takes 4: `−50`.
- Team bids 4, takes 5, and one partner successfully bid Nil: `+40 + 1 bag + 100 = +141`.
- Team bids 4, takes 6, and a Nil bidder takes a trick: `+40 + 2 bags − 100 = −58`.

### 5.7 End of game

- A game ends only after a completed round.
- A team reaching 500 or more points wins.
- If both teams reach 500 or more in the same round, the higher score wins.
- If scores are tied after both reach 500, play another round.
- “Play Again” returns all four connected players to a fresh lobby and clears game-specific state.

---

## 6. Host Authority and Privacy Model

### Host owns

- Random shuffle and deal
- Full deck and every private hand
- Seat order and team assignment
- Bids before reveal
- Current turn, led suit, and whether Spades are broken
- All played cards and trick history
- Tricks taken, team contracts, scores, bags, Nil outcomes, and game end
- The authoritative public snapshot after every accepted action

### Player owns

- Their device identity and display name
- Their private-hand UI
- Their bid submission
- Their requested card play

### Privacy requirements

- A player receives their own 13-card hand, never another player’s hand.
- The host must never broadcast a full game-state object containing all hands.
- Before bid reveal, a client receives only its own submitted/waiting state—not other bid values.
- After a card is played, it becomes public and is included in table/trick state.
- Clients cannot declare a trick winner, score a round, or advance the turn.

This is an honest-client anti-cheating model. It protects normal play by keeping hands private and validating moves centrally; it is not a claim of cryptographic security against a deliberately modified host device.

---

## 7. Apple Local-Network Architecture

Spades must use Apple’s Network framework from the beginning. Networking is part of the product’s foundation, not a post-game-engine integration.

### 7.1 Required framework pattern

- `NWListener` on the host phone
- `NWBrowser` on joiner phones
- `NWConnection` for each host/player connection
- TCP parameters with `includePeerToPeer = true`
- Bonjour discovery using the final Spades-specific service type
- Explicit `NSBonjourServices` and `NSLocalNetworkUsageDescription` in an explicit `Info.plist`
- Local-network permission prompt only after onboarding explains why it is needed

### 7.2 Queue and observation rules

The Seat proved these rules are non-negotiable for an `@MainActor @Observable` session manager:

- Start `NWListener`, `NWBrowser`, and every `NWConnection` on a dedicated background serial networking queue, never `.main`.
- Keep Network callbacks off the main thread.
- Hop only final UI/state mutations to the main actor.
- Delay the first receive loop by 0.3 seconds after a connection is ready so the joining UI renders first.
- Keep audio work off the main thread.

### 7.3 Connection resilience requirements

- Persist a short device ID in `UserDefaults`.
- Include player name and device ID in the join handshake.
- De-duplicate peers by device ID and endpoint base.
- Reject ghost connections that never complete the join handshake within three seconds.
- Use a three-second outgoing connection timeout.
- Ignore stale failed/cancelled callbacks by confirming the callback belongs to the current connection.
- Detect nil/error receive data as a disconnect every time.
- Maintain a reconnect circuit breaker so Bonjour churn cannot loop indefinitely.
- Do not rely on Simulator local-network discovery. Validate this system on real phones.

### 7.4 Transport framing

Every `SpadesMessage` uses JSON `Codable` payloads inside a 4-byte big-endian length-prefixed frame:

1. Encode the message to JSON.
2. Prefix it with a 4-byte big-endian payload length.
3. Send the complete frame.
4. Receive exactly 4 bytes.
5. Receive exactly the declared payload length.
6. Decode, handle, then begin the next receive cycle.

The receive loop must handle a disconnect before recursing. It must recurse after handling the message, not ahead of it.

---

## 8. Message Protocol Requirements

The final protocol belongs in a separate `SpadesMessage.swift`. The exact case names can evolve, but the following categories are required.

### Lobby and connection

- `join(name:deviceID:)`
- `lobbySnapshot(players:seats:teams:hostName:)`
- `teamAssignment(teams:)`
- `sessionRejected(reason:)`
- `sessionEnded(reason:)`

### Game start and private state

- `gameStarted(roundNumber:)`
- `privateHand(cards:)` — sent only to its owning player
- `publicGameSnapshot(...)` — public table, names, teams, turn, bids after reveal, scores, bags, and phase; never all hands

### Bidding

- `requestBid`
- `submitBid(tricks:)`
- `bidAccepted`
- `biddingProgress(submittedSeatIDs:)` — no values until reveal
- `bidsRevealed(bids:)`

### Card play and trick resolution

- `requestPlay`
- `playCard(cardID:)`
- `playRejected(reason:)`
- `cardPlayed(seatID:card:)`
- `trickResolved(winnerSeatID:cards:)`
- `roundResolved(scoreboard:nextDealer:)`

### Resilience and session control

- `gamePaused(reason:rejoinDeadline:)`
- `rejoin(deviceID:)`
- `gameResumed(snapshot:)`
- `gameOver(winningTeam:finalScoreboard:)`
- `heartbeat`

### Protocol safety requirements

- The host validates every decoded message against the current phase and sender’s assigned seat.
- A player can bid only while bidding is active and only once.
- A player can play only during their turn and only from their current private hand.
- A client ignores messages that do not make sense for its current session identity or phase.
- The host broadcasts the resulting authoritative state after every accepted game action.

---

## 9. Session and Round State Machine

### Session phases

1. **solo** — no session; browser may passively discover hosts after onboarding.
2. **hostingLobby** — host advertises a new session and occupies one seat.
3. **joiningLobby** — player is connecting and completing handshake.
4. **lobbyReady** — four players are present; teams can be confirmed.
5. **dealing** — host shuffles, deals private hands, and initializes the round.
6. **bidding** — bids collect privately.
7. **bidReveal** — all bids become public.
8. **playingTrick** — one current turn; public table grows from zero to four cards.
9. **trickResolution** — host announces winner and updates trick count.
10. **roundResolution** — host applies score, bags, and Nil results.
11. **gameOver** — final result and Play Again/Leave actions.
12. **pausedForReconnect** — only if the finalized disconnect policy allows it.
13. **ended** — teardown complete; return to solo/lobby entry.

### Host action contract

- The host may not start before exactly four players are connected and teams are assigned.
- The host may end a lobby or game deliberately at any time; players receive a session-ended message before teardown.
- The host cannot bypass card, bid, trick, or score validation through UI actions.

### Player action contract

- A player may leave from lobby or game, with an explicit confirmation during an active game.
- A player cannot edit teams, deal, reveal bids, or resolve a trick.
- A player sees a waiting state whenever another player owns the turn or the game is processing.

---

## 10. Screen Specification

### 10.1 Name and onboarding

Reuse The Seat’s successful gate:

1. Ask for a display name once.
2. Explain the nearby-game premise.
3. On the final onboarding slide, explain that local-network permission lets the phone find the three people in the room.
4. Only after onboarding completes may the solo screen begin browsing.

### 10.2 Solo / entry screen

**Purpose:** Start or join a nearby Spades game.

- Primary action: **Host a Game**
- Secondary action: **Join [Host Name]** when a host is discovered
- Host action is disabled when another visible host occupies the room, unless product design later supports multiple visible games.
- Settings entry is available here.

### 10.3 Host lobby

**Purpose:** Fill four seats and set teams.

- Four unmistakable seats: host plus three join positions.
- Connected names appear as players join.
- Host can assign Team Gold / Team Blue by moving players between fixed partner positions.
- Start remains disabled until all four slots are occupied and teams are valid.
- Clear waiting copy: “Waiting for 3 players,” then “Waiting for 2 players,” and so on.
- A player leaving reopens their seat and disables Start.

### 10.4 Player lobby

**Purpose:** Confirm a successful join and show the room forming.

- Show host name, own assigned seat, all connected players, and visible teams when assigned.
- Show a simple waiting state until the host starts.
- Leave returns to solo and resumes safe browsing behavior.

### 10.5 Bidding screen

**Purpose:** Let one player declare a private bid.

- Player’s 13-card hand remains visible.
- Bid control supports 0 through 13; 0 is visually labeled **Nil**.
- Submit requires a deliberate tap and cannot be changed after host acceptance.
- After submitting, show “Bid submitted — waiting for the table.”
- Do not reveal any other bid values until all four are in.
- After reveal, show both team contracts and every individual bid briefly before the first trick begins.

### 10.6 Main hand / table screen

**Purpose:** Play one trick at a time with no ambiguity.

- Own 13-card hand sits at the bottom in a horizontally scrollable, slightly overlapping layout.
- The current trick sits centered with up to four cards and clear seat orientation.
- Partner and opponents display name, bid, tricks won, and a turn indicator; never their hands.
- Current-turn state is obvious through a gold glow/label and restrained haptic when it becomes the local player’s turn.
- Legal cards receive a clear playable treatment. Illegal cards are dimmed.
- Interaction is two-stage: tap once to select, tap again to confirm play. This prevents accidental misplays.
- Once a card is accepted by the host, remove it from the local hand only after authoritative confirmation.
- A compact score affordance opens a score detail sheet without leaving the game state.

### 10.7 Trick resolution

**Purpose:** Make every won trick understandable.

- Briefly hold the four played cards.
- Highlight the winning card and winning player.
- Animate or transition the trick into the winner’s count.
- The winner becomes the next leader.
- Keep this fast; conversation should remain the center of the room.

### 10.8 Between-round score screen

**Purpose:** Explain scoring before the next deal.

- Show team bid, tricks taken, contract success/failure, bags earned, running bags, Nil result, and score change.
- Call out bag penalties clearly when they occur or approach.
- Show cumulative score toward 500.
- Host starts the next round once all players are ready, or auto-advances only if that later becomes a deliberate design choice.

### 10.9 Game over

**Purpose:** Land the result and offer a clean next step.

- Winning team and final score table
- Per-round/high-level game summary only; no full persistent history in v1
- **Play Again** returns connected players to a fresh lobby
- **Leave Game** tears down the session cleanly

### 10.10 Disconnect / pause screen

**Purpose:** Protect trust when a real-device network event happens.

- Name the disconnected player.
- Freeze interactions while the host waits for the rejoin policy.
- Show the remaining reconnect time if a timer is adopted.
- Explain the outcome if the game ends: “Game ended because [Name] did not reconnect.”
- Never quietly simulate a player or continue with an invalid private hand.

---

## 11. Game Models and Engine Boundaries

Keep game logic separate from SwiftUI and Network framework code so rules can be tested independently.

### Required models

- `Suit`: clubs, diamonds, hearts, spades
- `Rank`: two through ace, comparable within a suit
- `Card`: unique suit/rank identity
- `Deck`: creates, shuffles, and deals a standard deck
- `Seat`: north, east, south, west; clockwise order and partner lookup
- `Team`: two seats, bid, tricks, score, bags
- `Bid`: seat and integer 0...13
- `PlayedCard`: seat and card
- `Trick`: leader, led suit, cards in order, winner
- `RoundState`: hands, bids, current turn, Spades-broken flag, tricks, team totals
- `GameState`: teams, scoreboards, round number, session phase

### Engine responsibilities

- Deal exactly 13 unique cards to each seat
- Produce deterministic legal-play results from a hand and round state
- Identify trick winner correctly
- Advance seat order correctly
- Enforce 13 tricks per round
- Calculate contract, bags, Nil, penalties, and game winner
- Produce public snapshots without exposing private hands

### UI and transport must not own rules

- SwiftUI views request actions and render state.
- The host session manager moves validated game state through the engine.
- The networking layer transmits requests and authoritative results.
- No view or remote client decides whether a card is legal or who won a trick.

---

## 12. Audio, Haptics, and Visual Tone

### Audio

- Card placement: restrained card-slap sound
- Trick win: short, satisfying resolution cue
- Bid reveal: subtle table-ready cue
- Game win: modest celebratory cue
- Audio session uses `.playback` with `.mixWithOthers`, configured away from the main thread

### Haptics

- Local turn begins: light/medium haptic
- Card play accepted: light haptic
- Trick won: medium haptic for winner; light shared cue for others
- Set, Nil result, bag penalty, and game win: deliberate but not excessive feedback

### Visual direction

- Dark, focused game table rather than casino clutter
- Clean card faces at phone scale; oversized rank and suit symbols
- Gold accents belong to Spades/trump and important active state, not every surface
- Team colors must remain distinguishable without relying only on color
- The visual language should feel like a premium card table, not a generic web card game

---

## 13. Reliability and Lifecycle Requirements

### Backgrounding

- A host entering the background ends the live session in v1 unless a future architecture explicitly supports reliable host persistence.
- A player entering the background triggers the finalized pause/rejoin policy.
- On return, a solo player may resume browsing only after onboarding has completed.

### Voluntary leave

- Leaving during a lobby immediately frees the player’s seat.
- Leaving during a game must ask for confirmation because it ends or pauses the shared session according to the finalized policy.
- A device that voluntarily left must not immediately auto-rejoin a stale Bonjour advertisement.

### Host end

1. Host sends session-ended/game-ended message to all connected players.
2. Wait for send completion rather than cancelling connections immediately.
3. Tear down listener, browser, connections, and game state.
4. Return devices to their appropriate solo state.

---

## 14. Real-Device Validation Plan

Simulator networking is not valid proof for this app. The actual game must be exercised on real iPhones.

### Lobby and transport

- Host starts and advertises a game
- Three different phones discover and join
- Duplicate/ghost connections do not create duplicate seats
- Same display names receive clear differentiation if allowed
- Four slots fill accurately and team reassignment synchronizes
- Leaving/rejoining behavior matches the finalized policy

### Privacy and authority

- Each player receives exactly their own hand
- No device can see another hand through snapshots or logs
- A client cannot play out of turn
- A client cannot play a card it does not own
- A client cannot ignore follow-suit or lead Spades illegally
- Bids remain hidden until all four submit

### Rules engine

- All card ranks resolve correctly in each suit
- Spade trump wins appropriately
- Follow-suit enforcement holds across every void/non-void case
- First trick leader and subsequent winners advance correctly
- Spades-breaking rule handles both normal and all-spades-in-hand cases
- Nil success and failure score correctly
- Bags accumulate and penalize at 10, preserving any remainder
- Both teams reaching 500 resolves correctly, including ties

### Resilience

- Player disconnect while in lobby
- Player disconnect during bidding
- Player disconnect during an active trick
- Rejoin within the final window
- Rejoin after the final window
- Host disconnect/background behavior
- Repeated sessions and stale Bonjour results
- Wi-Fi unavailable / peer-to-peer discovery where supported

### Device coverage

- At minimum: iPhone 16 Pro and iPhone 13 mini
- Before release: validate a full four-device game with varied iPhone sizes and iOS versions supported by the app

---

## 15. Build Order

Do not rush straight to card visuals. The order protects the game’s integrity.

1. **Project foundation** — separate Xcode project/target, bundle ID, explicit `Info.plist`, iOS 17, Swift 5, unique service type, name/onboarding/solo shell.
2. **Pure Spades rules engine** — card models, deck, deal, legal plays, trick winner, turns, bids, scoring; test independently of UI/networking.
3. **Local-network lobby** — host/listener, player/browser, four slots, identity/de-duplication, team assignment, real-device joins.
4. **Host-authoritative protocol** — private hand delivery, bid flow, authoritative public snapshots, play requests and validation.
5. **Playable table UI** — hand, bid UI, current trick, turn state, trick resolution, score sheet.
6. **Round/game lifecycle** — round scoring, game over, Play Again, leave/end behavior, finalized disconnect policy.
7. **Polish** — audio, haptics, animations, accessibility, small-phone layouts, real-device stress testing.
8. **Commercial/release work** — only after the complete game is reliable: StoreKit strategy, App Store material, privacy policy, and a dedicated build-checklist dashboard.

---

## 16. Definition of V1 Complete

Spades v1 is complete only when four real phones can repeatedly:

1. Discover a host nearby and form a four-player lobby.
2. Assign teams and start a game.
3. Receive private 13-card hands.
4. Bid privately and reveal bids together.
5. Play legal cards through all 13 tricks with host enforcement.
6. See correct trick winners, scores, bags, and Nil results.
7. Finish a 500-point game or intentionally end it without stuck sessions.
8. Recover or end predictably under the finalized disconnect rule.
9. Start a clean new game afterward without stale connections, leaked state, or visible private cards.

---

## 17. Deferred Decisions Log

Keep this section until each item is explicitly decided; do not bury a decision in implementation.

- Final app name
- Bundle ID and Bonjour service type
- Final non-host disconnect/rejoin policy and timeout
- Whether host chooses teams or teams auto-fill by seat (current baseline: host chooses)
- Whether the score target remains 500 only in v1
- Whether next rounds require host confirmation or auto-advance
- Exact card art and table visual system
- Sound source and licensing
- StoreKit/paywall model, after a proven reusable implementation exists
