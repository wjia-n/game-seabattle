import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nautical.dart';
import '../theme/sea_themes.dart';
import 'menu_screen.dart' show storeUrl;
import 'pro_screen.dart';

/// Settings: audio, stats, share/rate, Pro shortcut.
class SettingsScreen extends StatelessWidget {
  final SeaAudio audio;
  final SeaSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  SeaThemeDef get theme =>
      SeaThemes.byId(settings.themeId, custom: settings.customTheme);

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Scaffold(
      backgroundColor: t.woodDark,
      body: WoodBackdrop(
        theme: t,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: t.brassLight),
                    onPressed: () {
                      audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  Text('Ship\'s Log', style: Nautical.title(24, theme: t)),
                ],
              ),
              const SizedBox(height: 8),
              ParchmentCard(
                theme: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('SOUND & MUSIC',
                        style: Nautical.label(12, theme: t)
                            .copyWith(color: t.ink.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    _switch(t, 'Music', settings.musicOn, (v) {
                      settings.setMusic(v);
                      audio.configure(
                          musicOn: v,
                          sfxOn: settings.sfxOn,
                          volume: settings.volume);
                      if (v) {
                        audio.startMenuMusic();
                      }
                    }),
                    _switch(t, 'Sound effects', settings.sfxOn, (v) {
                      settings.setSfx(v);
                      audio.configure(
                          musicOn: settings.musicOn,
                          sfxOn: v,
                          volume: settings.volume);
                      if (v) audio.click();
                    }),
                    const SizedBox(height: 4),
                    Text('Volume', style: Nautical.ink(14, theme: t)),
                    Slider(
                      value: settings.volume,
                      activeColor: t.brass,
                      inactiveColor: t.ink.withValues(alpha: 0.25),
                      onChanged: (v) {
                        settings.setVolume(v);
                        audio.configure(
                            musicOn: settings.musicOn,
                            sfxOn: settings.sfxOn,
                            volume: v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ParchmentCard(
                theme: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('VOYAGE RECORD',
                        style: Nautical.label(12, theme: t)
                            .copyWith(color: t.ink.withValues(alpha: 0.7))),
                    const SizedBox(height: 8),
                    _stat(t, 'Battles fought', '${settings.gamesPlayed}'),
                    _stat(t, 'Victories', '${settings.wins}'),
                    _stat(
                        t,
                        'Fewest shots to win',
                        settings.bestShots == 0
                            ? '—'
                            : '${settings.bestShots}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ParchmentCard(
                theme: t,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('MORE',
                        style: Nautical.label(12, theme: t)
                            .copyWith(color: t.ink.withValues(alpha: 0.7))),
                    const SizedBox(height: 8),
                    _rowBtn(t, Icons.workspace_premium,
                        settings.isPro ? 'Sea Battle PRO ✓' : 'Get Sea Battle PRO',
                        () {
                      audio.click();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ProScreen(audio: audio, settings: settings)),
                      );
                    }),
                    _rowBtn(t, Icons.share, 'Tell a friend', () {
                      audio.click();
                      Share.share(
                          'Come battle me in Sea Battle! $storeUrl');
                    }),
                    _rowBtn(t, Icons.star, 'Rate Sea Battle', () async {
                      audio.click();
                      try {
                        await InAppReview.instance.openStoreListing();
                      } catch (_) {}
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Image.asset('assets/wajiha_logo.png', height: 52),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Credits: WAJIHA',
                    style: Nautical.label(11, theme: t)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch(
      SeaThemeDef t, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Nautical.ink(15, theme: t))),
        Switch(
          value: value,
          activeThumbColor: t.brass,
          onChanged: (v) {
            audio.click();
            onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _stat(SeaThemeDef t, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Nautical.ink(15, theme: t))),
          Text(value,
              style: Nautical.ink(15, theme: t)
                  .copyWith(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _rowBtn(
      SeaThemeDef t, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: t.brass, size: 20),
                const SizedBox(width: 10),
                Text(label, style: Nautical.ink(15, theme: t)),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: t.ink.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
