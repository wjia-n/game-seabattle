import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/nautical.dart';
import '../theme/sea_themes.dart';

/// Custom sea-chart creator (PRO): pick every material color.
class CustomThemeScreen extends StatefulWidget {
  final SeaAudio audio;
  final SeaSettings settings;
  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  SeaAudio get audio => widget.audio;
  SeaSettings get settings => widget.settings;

  static const _slots = [
    ('woodDark', 'Dark wood'),
    ('woodMid', 'Mid wood'),
    ('brass', 'Brass'),
    ('brassLight', 'Bright brass'),
    ('parchment', 'Parchment'),
    ('parchmentDark', 'Aged parchment'),
    ('ink', 'Ink'),
    ('seaLight', 'Shallow sea'),
    ('seaDeep', 'Deep sea'),
    ('gridLine', 'Chart lines'),
    ('hitGlow', 'Hit glow'),
    ('missFoam', 'Miss foam'),
  ];

  static const _swatches = [
    0xFF3B2416, 0xFF6B4423, 0xFFC9A227, 0xFFE8CE7A,
    0xFFF1E4C3, 0xFFDCC99A, 0xFF2A1D10, 0xFF2E6E9E,
    0xFF12395C, 0xFF1F2A44, 0xFF33436B, 0xFFD4AF37,
    0xFF2BB3A3, 0xFF0E5E66, 0xFF4A1F14, 0xFF6E2F1C,
    0xFF1C2438, 0xFF2C3A55, 0xFFC0C6D4, 0xFFE0642A,
    0xFFDFF1F8, 0xFF101828, 0xFF7FB3C8, 0xFF8FD6C2,
  ];

  @override
  void initState() {
    super.initState();
    settings.addListener(_refresh);
  }

  @override
  void dispose() {
    settings.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = settings.customTheme;
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
                  Text('My Chart', style: Nautical.title(24, theme: t)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      audio.click();
                      settings.resetCustomColors();
                    },
                    child: Text('Reset',
                        style: TextStyle(
                            color: t.brassLight,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Live preview.
              Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.brass, width: 2.5),
                  gradient: LinearGradient(
                    colors: [t.seaLight, t.seaDeep],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.parchment,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.brass, width: 2),
                    ),
                    child: Text('Chart preview',
                        style: Nautical.ink(16, theme: t)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final slot in _slots) _slotRow(t, slot.$1, slot.$2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotRow(SeaThemeDef t, String key, String label) {
    final current = settings.customColors[key] ?? 0xFF000000;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Color(current),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: t.brass, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(label, style: Nautical.body(14, theme: t)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _swatches)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    settings.setCustomColor(key, s);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(s),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: current == s
                            ? Colors.white
                            : Colors.black26,
                        width: current == s ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
