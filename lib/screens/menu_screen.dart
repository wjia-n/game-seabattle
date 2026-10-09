import 'package:flutter/material.dart';
import '../engine/seabattle_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nautical.dart';
import '../theme/sea_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'custom_theme_screen.dart';

const storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.seabattle';

/// Main menu: battle setup, captains' names, theme + ship pickers, launch.
class MenuScreen extends StatefulWidget {
  final SeaAudio audio;
  final SeaSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final TextEditingController _name0;
  late final TextEditingController _name1;
  late final FocusNode _focus0;
  late final FocusNode _focus1;

  SeaSettings get s => widget.settings;
  SeaAudio get audio => widget.audio;

  @override
  void initState() {
    super.initState();
    _name0 = TextEditingController(text: s.playerNames[0]);
    _name1 = TextEditingController(text: s.playerNames[1]);
    _focus0 = FocusNode();
    _focus1 = FocusNode();
    // Commit on focus loss too (MASTER RULES: save on every keystroke AND
    // commit on focus loss) — onChanged covers keystrokes; this covers
    // the keyboard-dismiss path with no text change.
    _focus0.addListener(() {
      if (!_focus0.hasFocus) s.setPlayerName(0, _name0.text);
    });
    _focus1.addListener(() {
      if (!_focus1.hasFocus) s.setPlayerName(1, _name1.text);
    });
    s.addListener(_refresh);
    audio.startMenuMusic();
  }

  @override
  void dispose() {
    s.removeListener(_refresh);
    _name0.dispose();
    _name1.dispose();
    _focus0.dispose();
    _focus1.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  SeaThemeDef get theme =>
      SeaThemes.byId(s.themeId, custom: s.customTheme);

  void _start() {
    audio.gameStart();
    final players = [
      BattlePlayer(name: s.playerNames[0], isBot: false),
      BattlePlayer(
        name: s.playerNames[1],
        isBot: s.mode == 0, // vs AI: seat 2 is the bot
      ),
    ];
    final engine = SeaBattleEngine(
      players: players,
      fleet: FleetVariants.byId(s.fleetId),
      botDifficulty: BotDifficulty.values[s.difficulty],
      passAndPlay: s.mode == 1,
    );
    audio.startGameMusic();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: audio,
          settings: s,
          engine: engine,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Scaffold(
      backgroundColor: t.woodDark,
      body: WoodBackdrop(
        theme: t,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconBtn(Icons.settings, () {
                    audio.click();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(audio: audio, settings: s),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  _iconBtn(Icons.share, () {
                    audio.click();
                    Share.share(
                        'Come battle me in Sea Battle! $storeUrl');
                  }),
                  const SizedBox(width: 8),
                  _iconBtn(
                    s.isPro ? Icons.workspace_premium : Icons.lock_outline,
                    () {
                      audio.click();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProScreen(audio: audio, settings: s),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: t.brass, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        offset: const Offset(0, 8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/seabattle_logo.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                  child: Text('Sea Battle',
                      style: Nautical.display(40, theme: t))),
              const SizedBox(height: 16),
              _battleCard(t),
              const SizedBox(height: 14),
              _captainsCard(t),
              const SizedBox(height: 14),
              _themeCard(t),
              const SizedBox(height: 14),
              _shipsCard(t),
              const SizedBox(height: 20),
              Center(
                child: BrassButton(
                  label: 'SET SAIL',
                  icon: Icons.sailing,
                  theme: t,
                  primary: true,
                  onTap: _start,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  s.isPro
                      ? 'PRO admiral — fair winds!'
                      : 'Free version — unlock PRO for more seas & ships',
                  style: Nautical.body(12, theme: t).copyWith(
                    color: t.parchment.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    final t = theme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: t.woodDark.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.brass, width: 1.5),
          ),
          child: Icon(icon, color: t.brassLight, size: 20),
        ),
      ),
    );
  }

  Widget _battleCard(SeaThemeDef t) {
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('BATTLE PLAN', style: Nautical.label(12, theme: t).copyWith(color: t.ink.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _choice(
                  t,
                  selected: s.mode == 0,
                  label: 'Vs Captain AI',
                  sub: 'Solo duel',
                  onTap: () {
                    audio.click();
                    s.setMode(0);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _choice(
                  t,
                  selected: s.mode == 1,
                  label: '2 Admirals',
                  sub: 'Pass & play',
                  onTap: () {
                    audio.click();
                    s.setMode(1);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          if (s.mode == 0) ...[
            const SizedBox(height: 10),
            Text('AI skill', style: Nautical.ink(13, theme: t)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      child: _choice(
                        t,
                        selected: s.difficulty == i,
                        label: ['Cabin Boy', 'First Mate', 'Old Sea Dog'][i],
                        sub: i == 2 && !s.isPro ? 'PRO' : null,
                        locked: i == 2 && !s.isPro,
                        onTap: () {
                          audio.click();
                          s.setDifficulty(i);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text('Fleet', style: Nautical.ink(13, theme: t)),
          const SizedBox(height: 6),
          Column(
            children: [
              for (final f in FleetVariants.all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _choice(
                    t,
                    selected: s.fleetId == f.id,
                    label: f.name,
                    sub:
                        '${f.ships.length} ships · ${f.ships.join('-')}${f.pro && !s.isPro ? ' · PRO' : ''}',
                    locked: f.pro && !s.isPro,
                    onTap: () {
                      audio.click();
                      s.setFleet(f.id);
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _captainsCard(SeaThemeDef t) {
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CAPTAINS', style: Nautical.label(12, theme: t).copyWith(color: t.ink.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          _nameField(t, _name0, _focus0, 0, s.mode == 0 ? 'You' : 'Admiral 1'),
          const SizedBox(height: 8),
          _nameField(t, _name1, _focus1, 1, s.mode == 0 ? 'AI rival' : 'Admiral 2'),
        ],
      ),
    );
  }

  Widget _nameField(
      SeaThemeDef t,
      TextEditingController c,
      FocusNode focus,
      int idx,
      String hint) {
    return TextField(
      controller: c,
      focusNode: focus,
      maxLength: 16,
      style: Nautical.ink(16, theme: t),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.brass, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: t.brass, width: 1.5),
        ),
        prefixIcon: Icon(Icons.person, color: t.brass),
      ),
      onChanged: (v) => s.setPlayerName(idx, v),
    );
  }

  Widget _themeCard(SeaThemeDef t) {
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('SEA CHART',
                  style: Nautical.label(12, theme: t)
                      .copyWith(color: t.ink.withValues(alpha: 0.7))),
              const Spacer(),
              if (!s.isPro)
                Text('11 more in PRO',
                    style: Nautical.ink(11, theme: t)
                        .copyWith(color: t.ink.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: SeaThemes.all.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                if (i == SeaThemes.all.length) {
                  return _customThemeTile(t);
                }
                final th = SeaThemes.all[i];
                final locked = !s.isPro && SeaThemes.isProTheme(th.id);
                final selected = s.themeId == th.id;
                return GestureDetector(
                  onTap: () {
                    audio.click();
                    s.setTheme(th.id);
                    setState(() {});
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? t.brass : Colors.black26,
                        width: selected ? 3 : 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [th.seaLight, th.seaDeep],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 6),
                            child: Text(
                              th.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (locked)
                          Container(
                            color: Colors.black45,
                            child: const Icon(Icons.lock,
                                color: Colors.white70, size: 26),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _customThemeTile(SeaThemeDef t) {
    final selected = s.themeId == 'custom';
    final locked = !s.isPro;
    return GestureDetector(
      onTap: () {
        audio.click();
        if (locked) {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ProScreen(audio: audio, settings: s)),
          );
        } else {
          s.setTheme('custom');
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CustomThemeScreen(audio: audio, settings: s),
            ),
          );
        }
        setState(() {});
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? t.brass : Colors.black26,
            width: selected ? 3 : 1.5,
          ),
          gradient: LinearGradient(
            colors: [s.customTheme.seaLight, s.customTheme.seaDeep],
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.palette, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text('My Chart',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (locked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Icon(Icons.lock, color: Colors.white70, size: 26)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _shipsCard(SeaThemeDef t) {
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('FLEET STYLE',
                  style: Nautical.label(12, theme: t)
                      .copyWith(color: t.ink.withValues(alpha: 0.7))),
              const Spacer(),
              if (!s.isPro)
                Text('6 more in PRO',
                    style: Nautical.ink(11, theme: t)
                        .copyWith(color: t.ink.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ShipStyles.names.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final def = ShipStyles.of(i);
                final locked = !s.isPro && ShipStyles.isPro(i);
                final selected = s.shipStyle == i;
                return GestureDetector(
                  onTap: () {
                    audio.click();
                    s.setShipStyle(i);
                    setState(() {});
                  },
                  child: Container(
                    width: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? t.brass : Colors.black26,
                        width: selected ? 3 : 1.5,
                      ),
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 26),
                          child: CustomPaint(
                            painter: ShipCellPainter(
                              style: i,
                              def: def,
                              horizontal: true,
                              bow: true,
                              stern: true,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          right: 4,
                          child: Text(
                            def.name,
                            style: Nautical.ink(10, theme: t),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (locked)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                                child: Icon(Icons.lock,
                                    color: Colors.white70, size: 24)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice(
    SeaThemeDef t, {
    required bool selected,
    required String label,
    String? sub,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? t.brass.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.45),
          border: Border.all(
            color: selected ? t.brass : Colors.black26,
            width: selected ? 2.5 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Nautical.ink(14, theme: t)
                          .copyWith(fontWeight: FontWeight.w800)),
                  if (sub != null)
                    Text(sub,
                        style: Nautical.ink(11, theme: t).copyWith(
                            color: t.ink.withValues(alpha: 0.65))),
                ],
              ),
            ),
            if (locked)
              const Icon(Icons.lock, size: 18, color: Colors.black54)
            else if (selected)
              Icon(Icons.check_circle, size: 20, color: t.brass),
          ],
        ),
      ),
    );
  }
}

