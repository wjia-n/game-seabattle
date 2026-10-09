import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nautical.dart';
import '../theme/sea_themes.dart';
import 'menu_screen.dart';

/// Single launch splash with two moments:
/// 1. Company moment — the official WAJIHA logo alone on wood.
/// 2. Game splash — logo + name + animated loading line + "Credits: WAJIHA".
/// Audio is pre-warmed during the company moment.
class SplashScreen extends StatefulWidget {
  final SeaAudio audio;
  final SeaSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _gameMoment = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _run();
  }

  Future<void> _run() async {
    widget.audio.prewarm();
    widget.audio.startMenuMusic();
    // Company moment: the WAJIHA mark, alone, for a beat.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _gameMoment = true);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SeaThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.woodDark,
      body: WoodBackdrop(
        theme: theme,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _gameMoment ? _gameMomentWidget(theme) : _companyMoment(),
          ),
        ),
      ),
    );
  }

  /// Moment 1: the official WAJIHA logo, alone on wood.
  Widget _companyMoment() {
    return Column(
      key: const ValueKey('company'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/wajiha_logo.png', height: 120),
      ],
    );
  }

  /// Moment 2: game splash — logo + name + animated loading line +
  /// "Credits: WAJIHA".
  Widget _gameMomentWidget(SeaThemeDef theme) {
    return SingleChildScrollView(
      key: const ValueKey('game'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.brass, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/seabattle_logo.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 22),
          Text('Sea Battle', style: Nautical.display(52, theme: theme)),
          const SizedBox(height: 6),
          Text(
            'A NAUTICAL DUEL OF WITS',
            style: Nautical.label(13, theme: theme),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 220,
            child: AnimatedBuilder(
              animation: _loader,
              builder: (_, _) => Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                        color: theme.brass.withValues(alpha: 0.6),
                      ),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loader.value.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [theme.brassLight, theme.brass],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Loading the fleet…',
                      style: Nautical.body(13, theme: theme)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          Image.asset('assets/wajiha_logo.png', height: 64),
          const SizedBox(height: 8),
          Text('Credits: WAJIHA', style: Nautical.label(12, theme: theme)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
