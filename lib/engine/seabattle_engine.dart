import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../theme/sea_themes.dart';

/// Battleship rules live in RULES.md; this engine enforces them exactly.
///
/// Turn phases owned ENTIRELY by the engine. The UI only renders.
/// - [placing]: current placer arranges their fleet (human taps; bot auto).
/// - [passing]: pass-and-play handoff — the engine waits for
///   [acknowledgePass], nothing advances on its own.
/// - [aiming]: attacker chooses a cell (human taps; bot scheduled by engine).
/// - [firing]: shot in flight — visible cannonball animation, engine timer.
/// - [revealing]: result narration (HIT / SPLASH / SUNK), engine timer.
/// - [over]: game finished.
///
/// A watchdog recovers any phase found without a live timer, so stuck states
/// are impossible by construction. Every AI shot goes through firing +
/// revealing with narration — bots never silently auto-play.
enum BattlePhase { placing, passing, aiming, firing, revealing, over }

enum ShotResult { miss, hit, sunk }

class Ship {
  final List<Point<int>> cells;
  final Set<String> hits = {};
  Ship(this.cells);
  int get length => cells.length;
  bool get sunk => hits.length >= cells.length;
  String get name => shipNameFor(length);
  bool get horizontal =>
      cells.length < 2 || cells[0].x == cells[1].x;
}

class ShotAnim {
  final int attacker;
  final int row;
  final int col;
  final ShotResult result;
  final String? sunkShipName;
  final int totalMs;
  final DateTime startedAt = DateTime.now();

  ShotAnim({
    required this.attacker,
    required this.row,
    required this.col,
    required this.result,
    this.sunkShipName,
    this.totalMs = 950,
  });

  double get progress {
    final e = DateTime.now().difference(startedAt).inMilliseconds;
    return (e / totalMs).clamp(0.0, 1.0);
  }
}

class BattlePlayer {
  String name;
  final bool isBot;
  int shotsFired = 0;
  int hitsLanded = 0;
  BattlePlayer({required this.name, required this.isBot});
}

enum BotDifficulty { easy, medium, hard }

class SeaBattleEngine extends ChangeNotifier {
  static const boardSize = 10;

  final List<BattlePlayer> players; // exactly 2
  final BotDifficulty botDifficulty;
  final FleetVariant fleet;
  final bool passAndPlay;

  /// shots[a][r][c]: 0 unshot, 1 miss, 2 hit.
  late List<List<List<int>>> shots;
  late List<List<Ship>> fleets;

  BattlePhase phase = BattlePhase.placing;
  int placer = 0; // whose fleet is being placed
  int attacker = 0; // whose shot it is
  int passer = 0; // who the handoff screen is for

  // Placement state for the human placer.
  int placingShipIndex = 0;
  bool placingHorizontal = true;
  String? placementError;

  /// Select which ship the placer is placing, then refresh listeners.
  void selectPlacingShip(int i) {
    placingShipIndex = i;
    notifyListeners();
  }

  ShotAnim? shotAnim;
  String banner = '';
  bool over = false;
  int? winner;

  /// UI hook for sounds. Set by the screen.
  void Function(BattleEvent event)? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  static const fireMs = 950;
  static const revealMs = 1500;

  /// Bot hunt state: cells adjacent to unresolved hits.
  final List<Point<int>> _huntStack = [];

  SeaBattleEngine({
    required this.players,
    required this.fleet,
    this.botDifficulty = BotDifficulty.medium,
    this.passAndPlay = false,
  }) : assert(players.length == 2) {
    shots = [
      List.generate(boardSize, (_) => List.filled(boardSize, 0)),
      List.generate(boardSize, (_) => List.filled(boardSize, 0)),
    ];
    fleets = [[], []];
    // Bots place their fleet without being asked.
    if (_isBot(1)) {
      _autoPlace(1);
    }
    banner = _isBot(0)
        ? '${players[0].name} is arranging the fleet…'
        : '${players[0].name}: place your ${shipNameFor(fleet.ships[0])}!';
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _afterPhase();
  }

  bool _isBot(int i) => players[i].isBot;

  BattlePlayer get currentPlacer => players[placer];
  BattlePlayer get currentAttacker => players[attacker];

  bool get aimingHuman =>
      phase == BattlePhase.aiming && !_isBot(attacker) && !over;
  bool get placingHuman =>
      phase == BattlePhase.placing && !_isBot(placer) && !over;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: recover any phase found without a live timer.
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    if (phase == BattlePhase.firing && shotAnim != null) {
      final elapsed =
          DateTime.now().difference(shotAnim!.startedAt).inMilliseconds;
      final remain = (shotAnim!.totalMs - elapsed).clamp(50, shotAnim!.totalMs);
      _arm(Duration(milliseconds: remain), _revealShot);
    } else if (phase == BattlePhase.revealing) {
      _arm(const Duration(milliseconds: 400), _afterReveal);
    } else if (phase == BattlePhase.aiming && _isBot(attacker)) {
      _scheduleBotShot();
    } else if (phase == BattlePhase.placing && _isBot(placer)) {
      _finishPlacement(placer);
    }
    // BattlePhase.passing waits for the human handoff — correctly idle.
  }

  // ------------------------------------------------------------ placement
  bool _cellsFree(int pi, List<Point<int>> cells) {
    for (final c in cells) {
      if (c.x < 0 || c.x >= boardSize || c.y < 0 || c.y >= boardSize) {
        return false;
      }
    }
    for (final s in fleets[pi]) {
      for (final c in cells) {
        if (s.cells.contains(c)) return false; // RULES §5: no overlap
      }
    }
    return true;
  }

  List<Point<int>> _shipCells(int r, int c, int len, bool horizontal) {
    return [
      for (int k = 0; k < len; k++)
        Point(horizontal ? r : r + k, horizontal ? c + k : c),
    ];
  }

  /// Human places the current ship with its bow at (r, c).
  /// Returns false + sets [placementError] when illegal (RULES §5).
  bool placeShip(int r, int c) {
    if (!placingHuman || over) return false;
    final len = fleet.ships[placingShipIndex];
    final cells = _shipCells(r, c, len, placingHorizontal);
    if (!_cellsFree(placer, cells)) {
      placementError = 'No room there — ships may not overlap.';
      onEvent?.call(BattleEvent.invalid);
      notifyListeners();
      return false;
    }
    fleets[placer].add(Ship(cells));
    placementError = null;
    placingShipIndex++;
    onEvent?.call(BattleEvent.place);
    if (placingShipIndex >= fleet.ships.length) {
      _finishPlacement(placer);
    } else {
      banner =
          '${players[placer].name}: place your ${shipNameFor(fleet.ships[placingShipIndex])}!';
      notifyListeners();
    }
    return true;
  }

  void rotatePlacing() {
    if (!placingHuman) return;
    placingHorizontal = !placingHorizontal;
    notifyListeners();
  }

  void undoPlacedShip() {
    if (!placingHuman || fleets[placer].isEmpty) return;
    fleets[placer].removeLast();
    placingShipIndex = fleets[placer].length;
    placementError = null;
    onEvent?.call(BattleEvent.place);
    notifyListeners();
  }

  void shufflePlacement() {
    if (!placingHuman) return;
    _autoPlace(placer);
    placingShipIndex = fleet.ships.length;
    placementError = null;
    onEvent?.call(BattleEvent.place);
    _finishPlacement(placer);
  }

  void _autoPlace(int pi) {
    fleets[pi] = [];
    for (final len in fleet.ships) {
      bool ok = false;
      int guard = 0;
      while (!ok && guard++ < 5000) {
        final horiz = _rand.nextBool();
        final r = _rand.nextInt(boardSize);
        final c = _rand.nextInt(boardSize);
        final cells = _shipCells(r, c, len, horiz);
        if (!_cellsFree(pi, cells)) continue;
        fleets[pi].add(Ship(cells));
        ok = true;
      }
    }
  }

  void _finishPlacement(int pi) {
    if (over) return;
    placingShipIndex = fleet.ships.length;
    if (pi == 0 && passAndPlay && !_isBot(1)) {
      // Player 2 must not see player 1's fleet: handoff first.
      passer = 1;
      phase = BattlePhase.passing;
      banner = 'Pass to ${players[1].name} — no peeking!';
      notifyListeners();
      return;
    }
    _beginBattle();
  }

  /// Handoff screen confirmed: the passer now places or shoots.
  void acknowledgePass() {
    if (phase != BattlePhase.passing || over) return;
    onEvent?.call(BattleEvent.place);
    if (fleets[passer].isEmpty && !_isBot(passer)) {
      // Passer still has to place their fleet.
      placer = passer;
      phase = BattlePhase.placing;
      placingShipIndex = 0;
      placingHorizontal = true;
      placementError = null;
      banner =
          '${players[placer].name}: place your ${shipNameFor(fleet.ships[0])}!';
    } else {
      attacker = passer;
      _grantAim();
    }
    notifyListeners();
  }

  void _beginBattle() {
    phase = BattlePhase.aiming;
    attacker = 0;
    _grantAim();
    onEvent?.call(BattleEvent.gameStart);
  }

  // --------------------------------------------------------------- shooting
  void _grantAim() {
    phase = BattlePhase.aiming;
    shotAnim = null;
    if (_isBot(attacker)) {
      banner = '${players[attacker].name} is aiming…';
    } else {
      banner = '${players[attacker].name}: fire when ready!';
    }
    notifyListeners();
    _afterPhase();
  }

  void _afterPhase() {
    if (over || paused || _disposed) return;
    if (phase == BattlePhase.placing && _isBot(placer)) {
      _arm(const Duration(milliseconds: 800), () => _finishPlacement(placer));
    } else if (phase == BattlePhase.aiming && _isBot(attacker)) {
      _scheduleBotShot();
    }
  }

  void _scheduleBotShot() {
    if (over || phase != BattlePhase.aiming || !_isBot(attacker)) return;
    _arm(const Duration(milliseconds: 1100), () {
      if (over || phase != BattlePhase.aiming || !_isBot(attacker)) return;
      final cell = _botPickCell(attacker);
      _launchShot(attacker, cell.x, cell.y);
    });
  }

  /// Human taps the enemy chart. Illegal taps (already shot, wrong phase)
  /// are rejected with the invalid sound — never a stuck state (RULES §5).
  void fire(int r, int c) {
    if (!aimingHuman) return;
    if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) return;
    if (shots[attacker][r][c] != 0) {
      onEvent?.call(BattleEvent.invalid);
      banner = 'Already fired there — pick another square!';
      notifyListeners();
      return;
    }
    _launchShot(attacker, r, c);
  }

  void _launchShot(int atk, int r, int c) {
    if (over || phase != BattlePhase.aiming) return;
    final def = 1 - atk;
    ShotResult result = ShotResult.miss;
    String? sunkName;
    for (final s in fleets[def]) {
      if (s.cells.contains(Point(r, c))) {
        s.hits.add('$r,$c');
        shots[atk][r][c] = 2;
        if (s.sunk) {
          result = ShotResult.sunk;
          sunkName = s.name;
        } else {
          result = ShotResult.hit;
        }
        break;
      }
    }
    if (result == ShotResult.miss) {
      shots[atk][r][c] = 1;
    }
    players[atk].shotsFired++;
    if (result != ShotResult.miss) players[atk].hitsLanded++;

    // Bot hunt bookkeeping (RULES §11).
    if (_isBot(atk)) {
      if (result == ShotResult.hit) {
        for (final d in [
          const Point(1, 0),
          const Point(-1, 0),
          const Point(0, 1),
          const Point(0, -1)
        ]) {
          final nr = r + d.x, nc = c + d.y;
          if (nr >= 0 &&
              nr < boardSize &&
              nc >= 0 &&
              nc < boardSize &&
              shots[atk][nr][nc] == 0 &&
              !_huntStack.contains(Point(nr, nc))) {
            _huntStack.add(Point(nr, nc));
          }
        }
      } else if (result == ShotResult.sunk) {
        _huntStack.clear();
      }
    }

    shotAnim = ShotAnim(
      attacker: atk,
      row: r,
      col: c,
      result: result,
      sunkShipName: sunkName,
      totalMs: fireMs,
    );
    phase = BattlePhase.firing;
    final coord = '${'ABCDEFGHIJ'[r]}${c + 1}';
    banner = '${players[atk].name} fires at $coord…';
    onEvent?.call(BattleEvent.cannonFire);
    notifyListeners();
    _arm(const Duration(milliseconds: fireMs), _revealShot);
  }

  void _revealShot() {
    if (over || phase != BattlePhase.firing || shotAnim == null) return;
    phase = BattlePhase.revealing;
    final anim = shotAnim!;
    final atk = anim.attacker;
    final def = 1 - atk;
    final coord = '${'ABCDEFGHIJ'[anim.row]}${anim.col + 1}';
    switch (anim.result) {
      case ShotResult.miss:
        banner = 'SPLASH at $coord — missed!';
        onEvent?.call(BattleEvent.splash);
      case ShotResult.hit:
        banner = 'HIT at $coord! Fire again!';
        onEvent?.call(BattleEvent.explosion);
      case ShotResult.sunk:
        banner =
            '${anim.sunkShipName} SUNK at $coord! ${players[atk].name} fires again!';
        onEvent?.call(BattleEvent.sunk);
    }
    notifyListeners();
    if (_allSunk(def)) {
      _arm(const Duration(milliseconds: 900), () => _finish(atk));
    } else {
      _arm(const Duration(milliseconds: revealMs), _afterReveal);
    }
  }

  void _afterReveal() {
    if (over || phase != BattlePhase.revealing || shotAnim == null) return;
    final wasHit = shotAnim!.result != ShotResult.miss;
    shotAnim = null;
    if (wasHit) {
      // RULES §3: a hit earns another shot.
      _grantAim();
    } else {
      _passTurn();
    }
  }

  void _passTurn() {
    if (over) return;
    final next = 1 - attacker;
    if (passAndPlay && !_isBot(next)) {
      passer = next;
      attacker = next;
      phase = BattlePhase.passing;
      banner = 'Pass to ${players[next].name} — no peeking!';
      notifyListeners();
      return;
    }
    attacker = next;
    _grantAim();
  }

  bool _allSunk(int def) => fleets[def].every((s) => s.sunk);

  void _finish(int winIdx) {
    if (over) return;
    over = true;
    phase = BattlePhase.over;
    winner = winIdx;
    shotAnim = null;
    final w = players[winIdx];
    final sunk = fleets[1 - winIdx].where((s) => s.sunk).length;
    banner = '${w.name} rules the seas! ($sunk ships sunk)';
    notifyListeners();
    // In pass-and-play both seats are human; either way a human won.
    onEvent?.call(w.isBot ? BattleEvent.botWon : BattleEvent.humanWon);
  }

  void restart() {
    _timer?.cancel();
    paused = false;
    shots = [
      List.generate(boardSize, (_) => List.filled(boardSize, 0)),
      List.generate(boardSize, (_) => List.filled(boardSize, 0)),
    ];
    fleets = [[], []];
    for (final p in players) {
      p.shotsFired = 0;
      p.hitsLanded = 0;
    }
    _huntStack.clear();
    phase = BattlePhase.placing;
    placer = 0;
    attacker = 0;
    passer = 0;
    placingShipIndex = 0;
    placingHorizontal = true;
    placementError = null;
    shotAnim = null;
    over = false;
    winner = null;
    if (_isBot(1)) _autoPlace(1);
    banner = _isBot(0)
        ? '${players[0].name} is arranging the fleet…'
        : '${players[0].name}: place your ${shipNameFor(fleet.ships[0])}!';
    notifyListeners();
    _afterPhase();
  }

  // ---------------------------------------------------------------- bot AI
  /// RULES §11: difficulty scaling for shot selection.
  Point<int> _botPickCell(int atk) {
    final grid = shots[atk];
    List<Point<int>> unshotWhere(bool Function(int r, int c) test) {
      final out = <Point<int>>[];
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (grid[r][c] == 0 && test(r, c)) out.add(Point(r, c));
        }
      }
      return out;
    }

    final hunt = _huntStack.where((p) => grid[p.x][p.y] == 0).toList();
    switch (botDifficulty) {
      case BotDifficulty.easy:
        // Easy: fully random — playful, beatable.
        final all = unshotWhere((_, __) => true);
        return all[_rand.nextInt(all.length)];
      case BotDifficulty.medium:
        // Medium: hunt stack, else checkerboard parity, 25% pure noise.
        if (hunt.isNotEmpty &&
            !(_rand.nextDouble() < 0.25 && hunt.length > 1)) {
          return hunt[_rand.nextInt(hunt.length)];
        }
        final parity = unshotWhere((r, c) => (r + c) % 2 == 0);
        final pool = parity.isNotEmpty ? parity : unshotWhere((_, __) => true);
        return pool[_rand.nextInt(pool.length)];
      case BotDifficulty.hard:
        // Hard: hunt first (prefer cells extending a hit line), then the
        // parity cell with the most unshot neighbours. Deterministic.
        if (hunt.isNotEmpty) {
          hunt.sort((a, b) =>
              _lineScore(grid, b).compareTo(_lineScore(grid, a)));
          return hunt.first;
        }
        final parity = unshotWhere((r, c) => (r + c) % 2 == 0);
        final pool = parity.isNotEmpty ? parity : unshotWhere((_, __) => true);
        pool.sort((a, b) =>
            _neighbourScore(grid, b).compareTo(_neighbourScore(grid, a)));
        return pool.first;
    }
  }

  /// How many hit cells line up with [p] horizontally/vertically — chasing a
  /// ship's axis sinks it faster.
  int _lineScore(List<List<int>> grid, Point<int> p) {
    int score = 0;
    for (final d in [
      const Point(1, 0),
      const Point(-1, 0),
      const Point(0, 1),
      const Point(0, -1)
    ]) {
      final nr = p.x + d.x, nc = p.y + d.y;
      if (nr >= 0 &&
          nr < boardSize &&
          nc >= 0 &&
          nc < boardSize &&
          grid[nr][nc] == 2) {
        score += 2;
      }
    }
    return score;
  }

  int _neighbourScore(List<List<int>> grid, Point<int> p) {
    int score = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final nr = p.x + dr, nc = p.y + dc;
        if (nr >= 0 &&
            nr < boardSize &&
            nc >= 0 &&
            nc < boardSize &&
            grid[nr][nc] == 0) {
          score++;
        }
      }
    }
    return score;
  }
}

enum BattleEvent {
  cannonFire,
  splash,
  explosion,
  sunk,
  place,
  invalid,
  gameStart,
  humanWon,
  botWon,
}
