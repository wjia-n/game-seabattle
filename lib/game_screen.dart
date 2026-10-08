import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

class SeaBattleScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const SeaBattleScreen({super.key, required this.players, required this.callbacks});
  @override
  State<SeaBattleScreen> createState() => _SeaBattleScreenState();
}

class _Ship { List<Point<int>> cells; Set<String> hits = {}; _Ship(this.cells); }

class _SeaBattleScreenState extends State<SeaBattleScreen> {
  static const n = 10;
  static const fleets = [5, 4, 3, 3, 2];
  final rnd = Random();
  late List<List<_Ship>> boards;
  late List<List<List<int>>> shots; // shots[attacker][r][c]: 0 none,1 miss,2 hit
  String phase = 'place'; // place, pass, battle, overpass, done
  int placer = 0, attacker = 0, passer = 0;
  bool over = false;
  final List<Point<int>> botStack = [];

  bool get solo => widget.players.length == 1 || widget.players[1].isBot;
  int get humans => widget.players.where((p) => !p.isBot).length;

  @override
  void initState() {
    super.initState();
    boards = [[], []];
    shots = [List.generate(n, (_) => List.filled(n, 0)), List.generate(n, (_) => List.filled(n, 0))];
    _autoPlace(0);
    if (solo) _autoPlace(1);
  }

  void _autoPlace(int i) {
    boards[i] = [];
    for (final len in fleets) {
      bool ok = false;
      while (!ok) {
        final horiz = rnd.nextBool();
        final r = rnd.nextInt(n), c = rnd.nextInt(n);
        final cells = <Point<int>>[];
        for (int k = 0; k < len; k++) { cells.add(Point(horiz ? r : r + k, horiz ? c + k : c)); }
        if (cells.any((p) => p.x < 0 || p.x >= n || p.y < 0 || p.y >= n)) continue;
        if (boards[i].any((s) => s.cells.any((p) => cells.contains(p)))) continue;
        boards[i].add(_Ship(cells));
        ok = true;
      }
    }
    setState(() {});
  }

  String _fire(int atk, int r, int c) {
    final def = 1 - atk;
    if (shots[atk][r][c] != 0) return 'repeat';
    for (final s in boards[def]) {
      if (s.cells.contains(Point(r, c))) {
        s.hits.add('$r,$c');
        shots[atk][r][c] = 2;
        if (s.hits.length == s.cells.length) {
          widget.players[atk].score++;
          widget.callbacks.refreshHud();
          return 'sunk';
        }
        return 'hit';
      }
    }
    shots[atk][r][c] = 1;
    return 'miss';
  }

  bool _allSunk(int def) => boards[def].every((s) => s.hits.length == s.cells.length);

  void _playerFire(int r, int c) {
    if (phase != 'battle' || over) return;
    final res = _fire(attacker, r, c);
    if (res == 'repeat') return;
    Sfx.tap();
    setState(() {});
    if (res == 'sunk') { Sfx.win(); } else if (res == 'hit') { Sfx.move(); }
    if (_allSunk(1 - attacker)) { _end(attacker); return; }
    if (solo) {
      Future.delayed(const Duration(milliseconds: 750), _botFire);
    } else {
      passer = 1 - attacker;
      phase = 'overpass';
      setState(() {});
    }
  }

  void _botFire() {
    if (!mounted || over || phase != 'battle') return;
    Point<int> cell;
    if (botStack.isNotEmpty) {
      cell = botStack.removeLast();
    } else {
      final opts = <Point<int>>[];
      for (int r = 0; r < n; r++) { for (int c = 0; c < n; c++) {
        if (shots[1][r][c] == 0 && (r + c) % 2 == 0) { opts.add(Point(r, c)); }
      } }
      cell = opts[rnd.nextInt(opts.length)];
    }
    final res = _fire(1, cell.x, cell.y);
    if (res == 'hit') {
      for (final d in [Point(1,0), Point(-1,0), Point(0,1), Point(0,-1)]) {
        final nr = cell.x + d.x, nc = cell.y + d.y;
        if (nr >= 0 && nr < n && nc >= 0 && nc < n && shots[1][nr][nc] == 0) {
          botStack.add(Point(nr, nc));
        }
      }
    }
    if (res == 'sunk') botStack.clear();
    if (res != 'repeat') Sfx.tap();
    setState(() {});
    if (_allSunk(0)) _end(1);
  }

  void _end(int winner) {
    if (over) return; over = true; phase = 'done';
    Sfx.win();
    final w = widget.players[winner];
    widget.callbacks.finish(
      winner: w,
      headline: winner == 0 ? '🚢 Enemy fleet destroyed!' : '${w.emoji} ${w.name} rules the seas!',
      subline: 'Ships sunk: ${w.score}/5',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    if (phase == 'pass' || phase == 'overpass') return _passScreen(t);
    return Column(children: [
      const SizedBox(height: 6),
      ScoreChips(players: widget.players, activeIndex: phase == 'battle' ? attacker : placer),
      const SizedBox(height: 6),
      if (phase == 'place') ...[
        Text('🗺️ ${widget.players[placer].name}: arrange your fleet!',
            style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Expanded(child: _grid(t, boards[placer], null, true, 0)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            WajihaButton(label: 'Shuffle', emoji: '🔀', onTap: () { _autoPlace(placer); Sfx.tap(); }),
            WajihaButton(label: humans > 1 && placer == 0 ? 'Next admiral' : 'Start battle', emoji: '⚓',
                primary: true, onTap: () {
              Sfx.click();
              if (humans > 1 && placer == 0) { placer = 1; passer = 1; phase = 'pass'; }
              else { phase = 'battle'; attacker = 0; }
              setState(() {});
            }),
          ]),
        ),
      ] else ...[
        Text('🎯 ${widget.players[attacker].name}: fire when ready!',
            style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Expanded(flex: 6, child: _grid(t, boards[1 - attacker], shots[attacker], false, attacker)),
        Text('🛡️ your fleet', style: TextStyle(color: t.muted, fontSize: 12)),
        Expanded(flex: 4, child: _grid(t, boards[attacker], shots[1 - attacker], true, attacker)),
      ],
    ]);
  }

  Widget _passScreen(GameTheme t) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('🙈', style: const TextStyle(fontSize: 72)),
      const SizedBox(height: 12),
      Text('Pass to ${widget.players[passer].name}!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: t.text)),
      const SizedBox(height: 6),
      Text('No peeking at the other fleet 👀', style: TextStyle(color: t.muted)),
      const SizedBox(height: 16),
      WajihaButton(label: "I'm ${widget.players[passer].name}", emoji: '✅', primary: true, onTap: () {
        Sfx.click();
        setState(() {
          if (phase == 'pass') { phase = 'place'; }
          else { phase = 'battle'; attacker = passer; }
        });
      }),
    ]),
  );

  Widget _grid(GameTheme t, List<_Ship> fleet, List<List<int>>? shotGrid, bool mine, int viewer) {
    return LayoutBuilder(builder: (ctx, box) {
      final cell = min(box.maxWidth, box.maxHeight) / n;
      return Center(
        child: SizedBox(
          width: cell * n, height: cell * n,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: n),
            itemCount: n * n,
            itemBuilder: (c, i) {
              final r = i ~/ n, cc = i % n;
              final isShip = fleet.any((s) => s.cells.contains(Point(r, cc)));
              final shot = shotGrid?[r][cc] ?? 0;
              String label = '🌊';
              Color bg = t.surface;
              if (mine && isShip) { label = '🟩'; bg = t.primary.withValues(alpha: 0.35); }
              if (shot == 1) label = '💨';
              if (shot == 2) { label = '🔥'; bg = Colors.redAccent.withValues(alpha: 0.35); }
              return GestureDetector(
                onTap: (!mine && shotGrid != null) ? () => _playerFire(r, cc) : null,
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
                  child: Center(child: Text(label, style: const TextStyle(fontSize: 11))),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}
