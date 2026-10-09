import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/seabattle_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nautical.dart';
import '../theme/sea_themes.dart';
import 'menu_screen.dart' show storeUrl;

/// Battle screen: renders the engine's phases. The engine owns all state and
/// timing; this screen only draws and forwards taps.
class GameScreen extends StatefulWidget {
  final SeaAudio audio;
  final SeaSettings settings;
  final SeaBattleEngine engine;
  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.engine,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  SeaBattleEngine get e => widget.engine;
  bool _recorded = false;
  bool _reviewAsked = false;

  SeaThemeDef get theme =>
      SeaThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    e.addListener(_onEngine);
    e.onEvent = _onEvent;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    e.removeListener(_onEngine);
    e.onEvent = null;
    e.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      e.setPaused(true);
    } else if (state == AppLifecycleState.resumed) {
      // Keep the pause overlay up; the player resumes deliberately.
    }
  }

  void _onEngine() {
    if (!mounted) return;
    setState(() {});
    if (e.over && !_recorded) {
      _recorded = true;
      final humanWon = e.winner != null && !e.players[e.winner!].isBot;
      final shots = e.winner != null ? e.players[e.winner!].shotsFired : 0;
      widget.settings.recordGame(humanWon: humanWon, shots: shots);
      if (humanWon && !_reviewAsked && widget.settings.gamesPlayed >= 2) {
        _reviewAsked = true;
        _askReview();
      }
    }
  }

  Future<void> _askReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {
      // Graceful when not installed from Play.
    }
  }

  void _onEvent(BattleEvent event) {
    final a = widget.audio;
    switch (event) {
      case BattleEvent.cannonFire:
        a.cannon();
      case BattleEvent.splash:
        a.splashSfx();
      case BattleEvent.explosion:
        a.explosion();
      case BattleEvent.sunk:
        a.sunk();
      case BattleEvent.place:
        a.place();
      case BattleEvent.invalid:
        a.invalid();
      case BattleEvent.gameStart:
        break; // already played on launch
      case BattleEvent.humanWon:
        a.win();
      case BattleEvent.botWon:
        a.lose();
    }
  }

  void _quitToMenu() {
    widget.audio.click();
    widget.audio.startMenuMusic();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Scaffold(
      backgroundColor: t.woodDark,
      body: WoodBackdrop(
        theme: t,
        child: SafeArea(
          child: Stack(
            children: [
              _body(t),
              if (e.paused && !e.over) _pauseOverlay(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(SeaThemeDef t) {
    switch (e.phase) {
      case BattlePhase.passing:
        return _handoff(t);
      case BattlePhase.over:
        return _victory(t);
      case BattlePhase.placing:
        return _placing(t);
      case BattlePhase.aiming:
      case BattlePhase.firing:
      case BattlePhase.revealing:
        return _battle(t);
    }
  }

  // -------------------------------------------------------------- top bar
  Widget _topBar(SeaThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(child: _scoreChip(t, 0)),
          const SizedBox(width: 8),
          Expanded(child: _scoreChip(t, 1)),
          const SizedBox(width: 8),
          _smallBtn(t, Icons.pause, () {
            widget.audio.click();
            e.setPaused(true);
          }),
        ],
      ),
    );
  }

  Widget _scoreChip(SeaThemeDef t, int i) {
    final sunkCount = e.fleets[1 - i].where((s) => s.sunk).length;
    final total = e.fleets[1 - i].length;
    final active = !e.over &&
        ((e.phase == BattlePhase.aiming ||
                e.phase == BattlePhase.firing ||
                e.phase == BattlePhase.revealing) &&
            e.attacker == i);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: t.woodDark.withValues(alpha: 0.75),
        border: Border.all(
          color: active ? t.brassLight : t.brass.withValues(alpha: 0.5),
          width: active ? 2.5 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              e.players[i].name,
              style: Nautical.body(13, theme: t)
                  .copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$sunkCount/$total',
            style: TextStyle(
              color: t.brassLight,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBtn(SeaThemeDef t, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.woodDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.brass, width: 1.5),
          ),
          child: Icon(icon, color: t.brassLight, size: 18),
        ),
      ),
    );
  }

  Widget _banner(SeaThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: t.parchment.withValues(alpha: 0.92),
          border: Border.all(color: t.brass, width: 1.5),
        ),
        child: Text(
          e.banner,
          style: Nautical.ink(14, theme: t),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // -------------------------------------------------------------- placing
  Widget _placing(SeaThemeDef t) {
    final human = e.placingHuman;
    final fleet = e.fleet;
    final style = widget.settings.shipStyle;
    final shipDef = ShipStyles.of(style);
    return Column(
      children: [
        _topBar(t),
        _banner(t),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: human
                ? _Board(
                    key: const ValueKey('place'),
                    theme: t,
                    shots: e.shots[e.placer],
                    ships: e.fleets[e.placer],
                    showShips: true,
                    shipStyle: style,
                    shipDef: shipDef,
                    tappable: true,
                    onTapCell: (r, c) => e.placeShip(r, c),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                              color: t.brassLight),
                        ),
                        const SizedBox(height: 12),
                        Text(e.banner,
                            style: Nautical.body(15, theme: t)),
                      ],
                    ),
                  ),
          ),
        ),
        if (human) ...[
          // Fleet tray: pick which ship to place.
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: fleet.ships.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final placed = i < e.fleets[e.placer].length;
                final selected = i == e.placingShipIndex && !placed;
                final len = fleet.ships[i];
                return GestureDetector(
                  onTap: placed
                      ? null
                      : () {
                          widget.audio.click();
                          e.placingShipIndex = i;
                          // ignore: invalid_use_of_protected_member
                          e.notifyListeners();
                        },
                  child: Opacity(
                    opacity: placed ? 0.35 : 1.0,
                    child: Container(
                      width: 30 + len * 22.0,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: t.woodDark.withValues(alpha: 0.7),
                        border: Border.all(
                          color: selected ? t.brassLight : t.brass,
                          width: selected ? 2.5 : 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: CustomPaint(
                              painter: ShipCellPainter(
                                style: style,
                                def: shipDef,
                                horizontal: true,
                                bow: true,
                                stern: true,
                              ),
                            ),
                          ),
                          Text(
                            shipNameFor(len),
                            style: Nautical.body(9, theme: t),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (e.placementError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(e.placementError!,
                  style: TextStyle(
                      color: t.hitGlow, fontWeight: FontWeight.w700)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BrassButton(
                    label: 'Rotate',
                    icon: Icons.rotate_right,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      e.rotatePlacing();
                    }),
                BrassButton(
                    label: 'Shuffle',
                    icon: Icons.shuffle,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      e.shufflePlacement();
                    }),
                BrassButton(
                    label: 'Undo',
                    icon: Icons.undo,
                    theme: t,
                    onTap: e.fleets[e.placer].isEmpty
                        ? null
                        : () {
                            widget.audio.click();
                            e.undoPlacedShip();
                          }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --------------------------------------------------------------- battle
  Widget _battle(SeaThemeDef t) {
    final style = widget.settings.shipStyle;
    final shipDef = ShipStyles.of(style);
    final enemy = 1 - e.attacker;
    return Column(
      children: [
        _topBar(t),
        _banner(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
          child: Row(
            children: [
              Icon(Icons.crosshair, color: t.brassLight, size: 16),
              const SizedBox(width: 6),
              Text('Enemy waters — tap a square to fire',
                  style: Nautical.body(12, theme: t)),
            ],
          ),
        ),
        Expanded(
          flex: 62,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _EnemyBoard(
              theme: t,
              engine: e,
              enemyShips: e.fleets[enemy].where((s) => s.sunk).toList(),
              shipStyle: style,
              shipDef: shipDef,
              onFire: e.aimingHuman ? (r, c) => e.fire(r, c) : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
          child: Row(
            children: [
              Icon(Icons.shield, color: t.brassLight, size: 16),
              const SizedBox(width: 6),
              Text('Your fleet', style: Nautical.body(12, theme: t)),
            ],
          ),
        ),
        Expanded(
          flex: 38,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 2, 40, 10),
            child: _Board(
              key: const ValueKey('own'),
              theme: t,
              shots: e.shots[enemy],
              ships: e.fleets[e.attacker],
              showShips: true,
              shipStyle: style,
              shipDef: shipDef,
              tappable: false,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- handoff
  Widget _handoff(SeaThemeDef t) {
    final name = e.players[e.passer].name;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ParchmentCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🙈', style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Pass to $name!',
                  style: Nautical.ink(24, theme: t)
                      .copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('No peeking at the other fleet!',
                  style: Nautical.ink(14, theme: t)),
              const SizedBox(height: 18),
              BrassButton(
                label: "I'm $name",
                icon: Icons.check,
                theme: t,
                primary: true,
                onTap: () {
                  widget.audio.click();
                  e.acknowledgePass();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- victory
  Widget _victory(SeaThemeDef t) {
    final w = e.winner;
    final wName = w == null ? 'Nobody' : e.players[w].name;
    final humanWon = w != null && !e.players[w].isBot;
    final shots = w == null ? 0 : e.players[w].shotsFired;
    final hits = w == null ? 0 : e.players[w].hitsLanded;
    final acc = shots == 0 ? 0 : (hits * 100 / shots).round();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ParchmentCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(humanWon ? '🏆' : '🌊',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text('$wName rules the seas!',
                  style: Nautical.ink(24, theme: t)
                      .copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Shots fired: $shots   •   Hits: $hits   •   Accuracy: $acc%',
                style: Nautical.ink(14, theme: t),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  BrassButton(
                    label: 'Sail Again',
                    icon: Icons.replay,
                    theme: t,
                    primary: true,
                    onTap: () {
                      widget.audio.click();
                      _recorded = false;
                      e.restart();
                      widget.audio.startGameMusic();
                    },
                  ),
                  BrassButton(
                    label: 'Share',
                    icon: Icons.share,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      Share.share(
                          'I just ruled the seas in Sea Battle! Come battle me: $storeUrl');
                    },
                  ),
                  BrassButton(
                    label: 'Rate',
                    icon: Icons.star,
                    theme: t,
                    onTap: () async {
                      widget.audio.click();
                      try {
                        await InAppReview.instance.openStoreListing();
                      } catch (_) {}
                    },
                  ),
                  BrassButton(
                    label: 'Harbor',
                    icon: Icons.home,
                    theme: t,
                    onTap: _quitToMenu,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- pause
  Widget _pauseOverlay(SeaThemeDef t) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: ParchmentCard(
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Becalmed',
                  style: Nautical.ink(24, theme: t)
                      .copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('The battle waits for you.',
                  style: Nautical.ink(14, theme: t)),
              const SizedBox(height: 16),
              BrassButton(
                label: 'Resume',
                icon: Icons.play_arrow,
                theme: t,
                primary: true,
                onTap: () {
                  widget.audio.click();
                  e.setPaused(false);
                },
              ),
              const SizedBox(height: 10),
              BrassButton(
                label: 'Restart',
                icon: Icons.replay,
                theme: t,
                onTap: () {
                  widget.audio.click();
                  _recorded = false;
                  e.setPaused(false);
                  e.restart();
                },
              ),
              const SizedBox(height: 10),
              BrassButton(
                label: 'Harbor',
                icon: Icons.home,
                theme: t,
                onTap: _quitToMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Boards
// ===========================================================================

/// A 10x10 chart. Draws sea, grid, shot markers and ships (own fleet, or
/// revealed sunk enemy ships).
class _Board extends StatelessWidget {
  final SeaThemeDef theme;
  final List<List<int>> shots;
  final List<Ship> ships;
  final bool showShips;
  final int shipStyle;
  final ShipStyleDef shipDef;
  final bool tappable;
  final void Function(int r, int c)? onTapCell;

  const _Board({
    super.key,
    required this.theme,
    required this.shots,
    required this.ships,
    required this.showShips,
    required this.shipStyle,
    required this.shipDef,
    required this.tappable,
    this.onTapCell,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        final side = box.maxWidth < box.maxHeight
            ? box.maxWidth
            : box.maxHeight;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: GestureDetector(
              onTapDown: tappable && onTapCell != null
                  ? (d) {
                      final cell = side / 10;
                      final c = (d.localPosition.dx / cell)
                          .floor()
                          .clamp(0, 9);
                      final r = (d.localPosition.dy / cell)
                          .floor()
                          .clamp(0, 9);
                      onTapCell!(r, c);
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.brass, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: _SeaBoardPainter(
                    theme: theme,
                    shots: shots,
                    ships: showShips ? ships : const [],
                    shipStyle: shipStyle,
                    shipDef: shipDef,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeaBoardPainter extends CustomPainter {
  final SeaThemeDef theme;
  final List<List<int>> shots;
  final List<Ship> ships;
  final int shipStyle;
  final ShipStyleDef shipDef;

  _SeaBoardPainter({
    required this.theme,
    required this.shots,
    required this.ships,
    required this.shipStyle,
    required this.shipDef,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 10;
    // Sea with per-cell depth variation.
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final v = ((r * 31 + c * 17) % 7) / 7.0;
        final col = Color.lerp(theme.seaDeep, theme.seaLight, 0.35 + v * 0.3)!;
        canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell, cell), Paint()..color = col);
      }
    }
    // Wave texture.
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int r = 0; r < 10; r++) {
      final y = r * cell + cell * 0.5;
      final path = Path();
      for (double x = 0; x <= size.width; x += 8) {
        final yy = y + 3 * (0.5 + 0.5 * (x / 37 + r));
        if (x == 0) {
          path.moveTo(x, yy);
        } else {
          path.lineTo(x, yy);
        }
      }
      canvas.drawPath(path, wave);
    }
    // Ships under the markers.
    for (final s in ships) {
      _paintShip(canvas, s, cell);
    }
    // Grid lines.
    final grid = Paint()
      ..color = theme.gridLine.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (int i = 0; i <= 10; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, size.height), grid);
      canvas.drawLine(Offset(0, i * cell), Offset(size.width, i * cell), grid);
    }
    // Shot markers.
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final v = shots[r][c];
        if (v == 0) continue;
        final cx = c * cell + cell / 2;
        final cy = r * cell + cell / 2;
        if (v == 1) {
          // Miss: foam ring.
          canvas.drawCircle(
            Offset(cx, cy),
            cell * 0.22,
            Paint()
              ..color = theme.missFoam.withValues(alpha: 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
          canvas.drawCircle(
              Offset(cx, cy), cell * 0.08, Paint()..color = theme.missFoam);
        } else {
          // Hit: scorch + ember.
          canvas.drawCircle(
              Offset(cx, cy),
              cell * 0.34,
              Paint()..color = Colors.black.withValues(alpha: 0.55));
          canvas.drawCircle(
              Offset(cx, cy),
              cell * 0.20,
              Paint()..color = theme.hitGlow.withValues(alpha: 0.9));
          canvas.drawCircle(Offset(cx, cy), cell * 0.09,
              Paint()..color = Colors.white.withValues(alpha: 0.9));
        }
      }
    }
  }

  void _paintShip(Canvas canvas, Ship s, double cell) {
    final n = s.cells.length;
    for (int i = 0; i < n; i++) {
      final p = s.cells[i];
      final hit = s.hits.contains('${p.x},${p.y}');
      canvas.save();
      canvas.translate(p.y * cell, p.x * cell);
      ShipCellPainter(
        style: shipStyle,
        def: shipDef,
        horizontal: s.horizontal,
        bow: i == n - 1,
        stern: i == 0,
        hit: hit,
      ).paint(canvas, Size(cell, cell));
      canvas.restore();
      if (s.sunk) {
        // Wreck tint over sunk ships.
        canvas.drawRect(
          Rect.fromLTWH(p.y * cell, p.x * cell, cell, cell),
          Paint()..color = Colors.black.withValues(alpha: 0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeaBoardPainter old) => true;
}

/// Enemy board with tap-to-fire and the animated cannonball shot FX.
class _EnemyBoard extends StatefulWidget {
  final SeaThemeDef theme;
  final SeaBattleEngine engine;
  final List<Ship> enemyShips; // sunk ships, revealed
  final int shipStyle;
  final ShipStyleDef shipDef;
  final void Function(int r, int c)? onFire;

  const _EnemyBoard({
    required this.theme,
    required this.engine,
    required this.enemyShips,
    required this.shipStyle,
    required this.shipDef,
    this.onFire,
  });

  @override
  State<_EnemyBoard> createState() => _EnemyBoardState();
}

class _EnemyBoardState extends State<_EnemyBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fx;
  DateTime? _shotKey;

  @override
  void initState() {
    super.initState();
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: SeaBattleEngine.fireMs + SeaBattleEngine.revealMs),
    );
    _syncShot();
  }

  @override
  void didUpdateWidget(covariant _EnemyBoard old) {
    super.didUpdateWidget(old);
    _syncShot();
  }

  void _syncShot() {
    final s = widget.engine.shotAnim;
    if (s != null && s.startedAt != _shotKey) {
      _shotKey = s.startedAt;
      _fx.reset();
      _fx.forward();
    }
    if (s == null) _shotKey = null;
  }

  @override
  void dispose() {
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, box) {
        final side =
            box.maxWidth < box.maxHeight ? box.maxWidth : box.maxHeight;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: GestureDetector(
              onTapDown: widget.onFire != null
                  ? (d) {
                      final cell = side / 10;
                      final c =
                          (d.localPosition.dx / cell).floor().clamp(0, 9);
                      final r =
                          (d.localPosition.dy / cell).floor().clamp(0, 9);
                      widget.onFire!(r, c);
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.theme.brass, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(0, 6),
                      blurRadius: 14,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AnimatedBuilder(
                  animation: _fx,
                  builder: (_, __) => CustomPaint(
                    painter: _SeaBoardPainter(
                      theme: widget.theme,
                      shots: widget.engine.shots[widget.engine.attacker],
                      ships: widget.enemyShips,
                      shipStyle: widget.shipStyle,
                      shipDef: widget.shipDef,
                    ),
                    foregroundPainter: _ShotFxPainter(
                      shot: widget.engine.shotAnim,
                      fxT: _fx.value,
                      theme: widget.theme,
                    ),
                    size: Size(side, side),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cannonball flight + impact FX over the enemy chart.
class _ShotFxPainter extends CustomPainter {
  final ShotAnim? shot;
  final double fxT; // 0..1 over fireMs + revealMs
  final SeaThemeDef theme;

  _ShotFxPainter({required this.shot, required this.fxT, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final s = shot;
    if (s == null) return;
    final cell = size.width / 10;
    final target = Offset(s.col * cell + cell / 2, s.row * cell + cell / 2);
    final fireT = SeaBattleEngine.fireMs /
        (SeaBattleEngine.fireMs + SeaBattleEngine.revealMs);
    if (fxT < fireT) {
      // Cannonball arcs from the attacker's guns (bottom center) to target.
      final p = (fxT / fireT).clamp(0.0, 1.0);
      final eased = 1 - (1 - p) * (1 - p);
      final start = Offset(size.width / 2, size.height + cell * 0.5);
      final ctrl = Offset(
        (start.dx + target.dx) / 2,
        (start.dy < target.dy ? start.dy : target.dy) - size.height * 0.18,
      );
      final pos = Offset(
        (1 - eased) * (1 - eased) * start.dx +
            2 * (1 - eased) * eased * ctrl.dx +
            eased * eased * target.dx,
        (1 - eased) * (1 - eased) * start.dy +
            2 * (1 - eased) * eased * ctrl.dy +
            eased * eased * target.dy,
      );
      // Trail.
      for (int i = 1; i <= 4; i++) {
        final tp = (eased - i * 0.06).clamp(0.0, 1.0);
        final tx = (1 - tp) * (1 - tp) * start.dx +
            2 * (1 - tp) * tp * ctrl.dx +
            tp * tp * target.dx;
        final ty = (1 - tp) * (1 - tp) * start.dy +
            2 * (1 - tp) * tp * ctrl.dy +
            tp * tp * target.dy;
        canvas.drawCircle(
          Offset(tx, ty),
          cell * 0.10 * (1 - i * 0.18),
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
      }
      // Ball with fire glow.
      canvas.drawCircle(
          pos, cell * 0.20, Paint()..color = const Color(0xFFE0642A).withValues(alpha: 0.5));
      canvas.drawCircle(
          pos, cell * 0.13, Paint()..color = const Color(0xFF2A1D10));
    } else {
      // Impact: expanding rings — foam for miss, fire for hit/sunk.
      final p = ((fxT - fireT) / (1 - fireT)).clamp(0.0, 1.0);
      final miss = s.result == ShotResult.miss;
      for (int i = 0; i < 3; i++) {
        final rp = (p * 1.4 - i * 0.2).clamp(0.0, 1.0);
        if (rp <= 0) continue;
        canvas.drawCircle(
          target,
          cell * (0.15 + rp * 0.55),
          Paint()
            ..color = (miss ? theme.missFoam : theme.hitGlow)
                .withValues(alpha: (1 - rp) * 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5 * (1 - rp) + 1,
        );
      }
      if (!miss) {
        canvas.drawCircle(
            target,
            cell * 0.30 * (1 - p * 0.4),
            Paint()..color = theme.hitGlow.withValues(alpha: 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShotFxPainter old) => true;
}
