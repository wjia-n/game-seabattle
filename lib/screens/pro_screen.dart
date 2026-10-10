import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/nautical.dart';
import '../theme/sea_themes.dart';

/// Pro screen: Free-vs-Pro comparison, Pro unlock, tip jar, restore.
/// Honest states when the store isn't configured yet.
class ProScreen extends StatefulWidget {
  final SeaAudio audio;
  final SeaSettings settings;
  const ProScreen({super.key, required this.audio, required this.settings});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;

  SeaThemeDef get theme => SeaThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    _store.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  
  @override
  void dispose() {
    _store.dispose();
    super.dispose();
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
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: t.brassLight),
                    onPressed: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                  Text('Sea Battle PRO', style: Nautical.title(24, theme: t)),
                ],
              ),
              const SizedBox(height: 8),
              _compareCard(t),
              const SizedBox(height: 14),
              _buyCard(t),
              const SizedBox(height: 14),
              _tipJar(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _compareCard(SeaThemeDef t) {
    const rows = [
      ('Sea charts', '4', 'All 15 + custom'),
      ('Fleet styles', '3', 'All 9'),
      ('Custom chart creator', '—', '✓'),
      ('AI rival skill', '2 levels', '3 levels incl. Old Sea Dog'),
      ('Fleet variants', '2', 'All 3 incl. Grand Armada'),
      ('Admiring looks', 'some', 'many'),
    ];
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FREE vs PRO',
              style: Nautical.label(12, theme: t)
                  .copyWith(color: t.ink.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.4),
            },
            children: [
              TableRow(
                children: [
                  _cell(t, '', header: true),
                  _cell(t, 'FREE', header: true),
                  _cell(t, 'PRO', header: true, gold: true),
                ],
              ),
              for (final r in rows)
                TableRow(
                  children: [
                    _cell(t, r.$1),
                    _cell(t, r.$2),
                    _cell(t, r.$3, gold: true),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(SeaThemeDef t, String text,
      {bool header = false, bool gold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: Nautical.ink(13, theme: t).copyWith(
          fontWeight: header ? FontWeight.w900 : FontWeight.w600,
          color: gold ? const Color(0xFF8A6D1A) : t.ink,
        ),
        textAlign: gold || header ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buyCard(SeaThemeDef t) {
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.settings.isPro) ...[
            Row(
              children: [
                Icon(Icons.workspace_premium, color: t.brass, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('You are a PRO admiral. Fair winds!',
                      style: Nautical.ink(16, theme: t)
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ] else if (_loading) ...[
            Center(
                child: Padding(
              padding: const EdgeInsets.all(12),
              child: CircularProgressIndicator(color: t.brass),
            )),
          ] else if (!_store.storeReady) ...[
            Text('PRO unlock',
                style: Nautical.ink(17, theme: t)
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              _store.error ?? 'Available after store setup',
              style: Nautical.ink(14, theme: t),
            ),
            const SizedBox(height: 4),
            Text(
              'The one-time PRO upgrade will appear here once the store listing is finished.',
              style: Nautical.ink(12, theme: t)
                  .copyWith(color: t.ink.withValues(alpha: 0.7)),
            ),
          ] else ...[
            Text('Unlock PRO forever',
                style: Nautical.ink(17, theme: t)
                    .copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            if (_store.proProduct != null)
              Text(_store.proProduct!.price,
                  style: Nautical.ink(22, theme: t)
                      .copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ValueListenableBuilder<bool>(
              valueListenable: _store.purchaseInProgress,
              builder: (_, busy, __) => BrassButton(
                label: busy ? 'Working…' : 'BECOME PRO',
                icon: Icons.workspace_premium,
                theme: t,
                primary: true,
                onTap: busy ? null : () => _store.buyPro(),
              ),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _store.purchaseError,
              builder: (_, err, __) => err == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(err,
                          style: TextStyle(
                              color: t.hitGlow,
                              fontWeight: FontWeight.w700)),
                    ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                widget.audio.click();
                _store.restore();
              },
              child: Text('Restore purchases',
                  style: TextStyle(
                      color: t.brass,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline)),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: _store.lastThanks,
            builder: (_, thanks, __) => thanks == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('🎉 $thanks',
                        style: Nautical.ink(14, theme: t)
                            .copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tipJar(SeaThemeDef t) {
    return ParchmentCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('TIP JAR',
              style: Nautical.label(12, theme: t)
                  .copyWith(color: t.ink.withValues(alpha: 0.7))),
          const SizedBox(height: 6),
          Text('Love the game? Buy the captain a treat. 100% optional.',
              style: Nautical.ink(13, theme: t)),
          const SizedBox(height: 10),
          if (_loading)
            Center(
                child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircularProgressIndicator(color: t.brass),
            ))
          else if (!_store.storeReady)
            Text(_store.error ?? 'Available after store setup',
                style: Nautical.ink(13, theme: t)
                    .copyWith(color: t.ink.withValues(alpha: 0.7)))
          else
            ValueListenableBuilder<bool>(
              valueListenable: _store.purchaseInProgress,
              builder: (_, busy, __) => Row(
                children: [
                  Expanded(
                    child: _tipBtn(
                      t,
                      '☕ Coffee',
                      _store.coffeeProduct?.price ?? '',
                      busy,
                      () {
                        final p = _store.coffeeProduct;
                        if (p != null) _store.buyTip(p);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _tipBtn(
                      t,
                      '🍫 Chocolate',
                      _store.chocolateProduct?.price ?? '',
                      busy,
                      () {
                        final p = _store.chocolateProduct;
                        if (p != null) _store.buyTip(p);
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tipBtn(SeaThemeDef t, String label, String price, bool busy,
      VoidCallback onTap) {
    return BrassButton(
      label: price.isEmpty ? label : '$label\n$price',
      theme: t,
      onTap: busy ? null : () {
        widget.audio.click();
        onTap();
      },
    );
  }
}