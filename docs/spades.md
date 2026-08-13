# Spades

**Status:** Concept phase. Separate app — reuses networking layer from The Seat/HCF.

## Core Concept

4-player trick-taking card game with teams. Played on phones, in the same room, over local network. No internet, no accounts, no setup. Host creates game, 3 players join, play Spades.

## Why This Works

- People actually play Spades — it's not a dead game
- Teams of 2 create social tension (partner dynamics, trash talk)
- Private hands on phones = no peeking, no card holders needed
- Same networking layer (NWBrowser + NWListener + NWConnection, peer-to-peer)
- Game state is authoritative on host — no cheating possible
- 4 players is a fixed, clean constraint

## Tech

- Port networking layer from The Seat (NWBrowser + NWListener + NWConnection, includePeerToPeer)
- Service type: TBD (e.g. `_spades._tcp`)
- Host = dealer + game authority
- SessionManager pattern (@MainActor @Observable)
- SwiftUI, no backend, pure Apple frameworks
- StoreKit 2 paywall (same pattern)
- iOS 17+ deployment target

## Game Rules (Standard Spades)

### Setup
- 4 players, 2 teams (partners sit across from each other)
- Standard 52-card deck, all cards dealt (13 per player)
- Spades are always trump

### Bidding
- Each player bids how many tricks they think they'll win (1–13)
- Bids are private, revealed simultaneously after all 4 submit
- Team bid = sum of both partners' bids
- Nil bid: player bids 0 (bonus if successful, penalty if they take any trick)

### Play
- Player to host's left leads first trick
- Must follow suit if able
- If void in led suit, may play any card (including spades)
- Spades can't be led until "broken" (a spade has been played on a non-spade trick)
- Highest card of led suit wins, unless a spade was played — then highest spade wins
- Trick winner leads next trick

### Scoring
- Make your bid: 10 points per trick bid (e.g., bid 4 = 40 points if you take 4+)
- Overtricks (bags): +1 point each, but 10 cumulative bags = -100 penalty
- Fail bid (set): -10 points per trick bid
- Nil success: +100 points
- Nil fail: -100 points
- Game ends at 500 points (configurable)

## Networking Flow

### Message Types
```
enum SpadesMessage: Codable {
    // Lobby
    case join(name: String, deviceID: String)
    case lobbyUpdate(players: [String], teams: [[String]])
    
    // Game setup
    case dealCards([Card])
    case startBidding
    case bid(tricks: Int)
    case allBids(bids: [String: Int])
    
    // Gameplay
    case yourTurn
    case playCard(Card)
    case cardPlayed(player: String, card: Card)
    case trickResult(winner: String, cards: [Card])
    case roundResult(scores: [String: Int], bags: [String: Int])
    
    // Meta
    case gameOver(winner: String, finalScores: [String: Int])
    case sessionEnd
    case heartbeat
}
```

### Host Responsibilities
- Shuffle and deal
- Collect bids, reveal together
- Track turn order
- Validate plays (must follow suit, spades broken check)
- Resolve trick winner
- Calculate scores + bags
- Determine game end

### Player Responsibilities
- Display own hand
- Submit bid
- Play a card on their turn
- View current trick and scores

## UI Screens

### Lobby (pre-game)
- Host sees 4 slots (self + 3 open)
- Players join, fill slots
- Team assignment (auto or manual)
- "Start Game" when 4 players connected

### Hand View (main game screen)
- Fan of 13 cards at bottom (scrollable or arc)
- Current trick in center (up to 4 cards)
- Player names at top/sides with bid info
- Whose turn indicator (glow or highlight)
- Score display accessible

### Bidding Screen
- Shows your hand
- Slider or picker for bid (0–13)
- Submit button
- Waiting indicator for other players

### Between Rounds
- Score summary
- Bags warning if approaching 10
- "Next Round" or auto-advance

### Game Over
- Final scores
- Winner announcement
- "Play Again" button

## Card Display

### The 13-card hand problem
- Options: horizontal scroll, fan arc, 2-row grid
- Recommended: horizontal scroll with slight overlap (like real cards in hand)
- Tap to select, tap again to play (prevents misplays)
- Playable cards highlighted, unplayable dimmed (must follow suit enforcement)

### Card Design
- Clean, readable at phone scale
- Large suit symbol + rank
- Dark theme consistent with other apps
- Gold accents for spades suit (thematic)

## Team Assignment

### Options
1. Auto-assign (players 1&3 vs 2&4 by join order)
2. Host picks teams in lobby
3. Random shuffle

Recommendation: Host picks teams (keeps it social — "you two vs us two")

## Open Questions

1. App name? "Spades" is generic — need something with personality
2. Blind Nil — include or not? (high risk/reward variant)
3. Jokers variant — some versions use 2 jokers as high trump
4. Minimum bid — some house rules require bid of 1 minimum (no everyone-bids-nil)
5. Bags threshold — standard is 10, some play 7
6. Winning score — 500 is standard, option for 300 or 200 for shorter games?
7. What happens if a player disconnects mid-game? AI takes over? Game paused?
8. Spectator mode? (5th person watches?)
9. Card dealing animation or instant?
10. Sound design — card slap sounds? Trick win fanfare?

## Reusable From The Seat

- SessionManager architecture (@MainActor @Observable)
- Network framework peer-to-peer (NWBrowser/NWListener/NWConnection)
- Toast system (per-screen, x/y positioning)
- Onboarding flow (slides + network permission prime)
- Settings view pattern
- Audio/haptic system (preloaded AVAudioPlayer, dedicated audio queue)
- Build checklist HTML dashboard template
- Paywall (StoreKit 2 / StoreManager pattern)
- Background queue networking, MainActor hops for state
- Connection dedup, device ID dedup, ghost timeout
- Length-prefixed JSON message framing

## What's New (Not Portable)

- Card model (suit, rank, comparable for trick resolution)
- Deck shuffling + dealing logic
- Trick resolution engine (follow suit, trump, highest card)
- Scoring engine (bids, bags, nil, set)
- Turn management (circular, 13 tricks per round)
- Card fan UI component
- Trick display component
- Team management
- Multi-round game state persistence
