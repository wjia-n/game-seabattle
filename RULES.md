# Sea Battle — Rules

The authoritative rules for Sea Battle (package `com.gameswajiha.seabattle`).
The engine (`lib/engine/seabattle_engine.dart`) enforces these exactly. If the
implementation ever conflicts with this document, fix the implementation.

## 1. Objective

Sink the entire enemy fleet before the enemy sinks yours. A fleet is destroyed
when every ship in it is sunk (§9).

## 2. Setup

- Two admirals play on separate 10×10 charts (columns 1–10, rows A–J).
- Each admiral secretly arranges their fleet on their own chart before battle.
- Fleet variants:
  - **Standard Fleet:** Carrier 5, Battleship 4, Cruiser 3, Cruiser 3,
    Destroyer 2.
  - **Quick Skirmish:** Battleship 4, Cruiser 3, Destroyer 2.
  - **Grand Armada (PRO):** Dreadnought 6, Carrier 5, Battleship 4,
    Cruiser 3, Cruiser 3, Destroyer 2.
- Modes: **Vs Captain AI** (seat 2 is the bot, 3 difficulties) or
  **2 Admirals** (local pass-and-play; the device is handed over with a
  no-peeking screen between turns).
- The bot's fleet is always placed automatically and fairly at random.

## 3. Turn order

- Admiral 1 (seat 1) shoots first.
- A **hit** (including a sinking hit) earns another shot immediately —
  the same admiral keeps firing while they keep hitting.
- A **miss** passes the turn to the other admiral.
- In pass-and-play, a device handoff screen ("Pass to X — no peeking!")
  appears before the other admiral's chart becomes visible.

## 4. Legal moves

- Firing at any chart square that has not been fired at before.
- During placement: placing the selected ship on empty squares inside the
  10×10 chart, horizontally or vertically.

## 5. Illegal moves

- Firing at a square already fired at (rejected with a warning + sound;
  the turn is NOT consumed).
- Firing while it is not your turn, while a shot is animating, or after
  the game is over.
- Placing a ship that overlaps another ship or hangs off the chart edge.
- Ships may touch each other (adjacency is allowed); only overlap is
  forbidden.

## 6. Captures

Not applicable — there are no captures in Sea Battle. (Hits and sinkings
are covered in §9.)

## 7. Special rules

- **Sinking shot bonus:** sinking an enemy ship counts as a hit — the
  shooter fires again (§3).
- **Handoff secrecy:** in pass-and-play, charts are never shown to the
  wrong admiral; every turn change goes through the handoff screen.
- **Bot visibility:** every AI shot is fully animated with narration
  ("Old Salt fires at C4… HIT!"). Bots never silently auto-play.

## 8. Scoring

- Each sunk enemy ship scores 1 point for the shooter (shown as
  `sunk/total` on the score chips).
- Voyage record (persisted): battles fought, victories, fewest shots to a
  win.

## 9. Winning conditions

The first admiral to sink every ship of the enemy fleet wins the battle.
Ship names by length for the sinking call: 6 Dreadnought, 5 Carrier,
4 Battleship, 3 Cruiser, 2 Destroyer.

## 10. Draw conditions

None — every battle ends with a winner. (There is no turn limit.)

## 11. AI strategy

- **Cabin Boy (easy):** fires at fully random unfired squares. Playful
  and beatable.
- **First Mate (medium):** hunts around hits (orthogonal neighbours) and
  otherwise fires on a checkerboard parity pattern (no ship can hide
  between parity squares... almost — size-2+ ships always touch a parity
  square); 25% of the time it plays a random square to stay human.
- **Old Sea Dog (hard, PRO):** hunts hits first, preferring cells that
  extend an established hit line (sinks ships along their axis), then the
  parity square with the most unfired neighbours. Deterministic.
- All difficulties place their fleet at random; difficulty only affects
  shooting.

## 12. Edge cases

- Firing at an already-fired square: rejected, turn not consumed.
- Three... (no forfeit rule — every turn always has a legal shot until
  the board is full, which cannot happen before a fleet is sunk).
- App backgrounded mid-shot: the engine freezes its timers; resuming
  re-arms the current phase, and a watchdog recovers any phase found
  without a live timer. Stuck states are impossible by construction.
- Restart mid-battle: fleets, shots and scores reset; placement restarts
  with Admiral 1.

## 13. Test cases

1. Place all ships legally → battle begins, Admiral 1 aims.
2. Overlap a ship → rejected with message; ship not placed.
3. Ship off the chart edge → rejected.
4. Fire at an unfired square → cannon animation → hit/miss narration.
5. Fire at an already-fired square → rejected, turn kept.
6. Hit → same admiral fires again (banner says so).
7. Miss → turn passes (with handoff screen in pass-and-play).
8. Sink the last enemy ship → victory screen with stats; voyage record
   updated.
9. Background the app mid-animation → foreground → shot completes, no
   stuck state.
10. Bot turn (any difficulty) → aiming narration → visible cannonball →
    result narration; never instant.
11. Rename both captains → restart app → names preserved in order.
12. PRO-only theme/ship/difficulty/fleet selected while free → ignored
    (UI shows lock); after PRO purchase → selectable and persisted.
