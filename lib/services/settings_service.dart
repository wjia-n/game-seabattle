import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/sea_themes.dart';

/// Persisted settings + stats for Sea Battle.
///
/// Stores: audio toggles, player names (2 seats), theme/appearance choices
/// (incl. custom theme colors), game-mode setup (vs AI / pass-and-play,
/// difficulty, fleet variant), Pro unlock state, and lifetime stats.
class SeaSettings extends ChangeNotifier {
  static const _kMusic = 'seabattle_music_on';
  static const _kSfx = 'seabattle_sfx_on';
  static const _kVolume = 'seabattle_volume';
  static const _kMode = 'seabattle_mode'; // 0 vs AI, 1 pass-and-play
  static const _kDifficulty = 'seabattle_bot_difficulty'; // 0 easy, 1 med, 2 hard
  static const _kFleet = 'seabattle_fleet_id';
  static const _kNames = 'seabattle_player_names'; // legacy unordered key
  /// Order-safe player-name storage: a single JSON string. Android's
  /// SharedPreferences stores StringLists as an unordered StringSet, so the
  /// old key scrambled name order on every app restart. Never use a
  /// StringList for ordered data on Android.
  static const _kNamesJson = 'seabattle_player_names_json';
  static const _kTheme = 'seabattle_theme_id';
  static const _kShipStyle = 'seabattle_ship_style';
  static const _kWins = 'seabattle_wins';
  static const _kGames = 'seabattle_games_played';
  static const _kBestShots = 'seabattle_best_shots'; // fewest shots to win
  static const _kIsPro = 'seabattle_is_pro';
  static const _kCustomPrefix = 'seabattle_custom_';

  static const defaultNames = ['Captain', 'Old Salt'];

  static String encodePlayerNames(List<String> names) => jsonEncode(names);

  static String _cleanName(int i, Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultNames[i] : s;
  }

  static List<String> decodePlayerNames(String? raw) {
    if (raw == null) return List.of(defaultNames);
    try {
      final d = jsonDecode(raw);
      if (d is List && d.length == 2) {
        return [for (int i = 0; i < 2; i++) _cleanName(i, d[i])];
      }
    } catch (_) {}
    return List.of(defaultNames);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  int mode = 0; // 0 vs AI, 1 pass-and-play
  int difficulty = 1; // medium default
  String fleetId = 'standard';
  List<String> playerNames = List.of(defaultNames);
  String themeId = 'classic';
  int shipStyle = 0;
  int wins = 0;
  int gamesPlayed = 0;
  int bestShots = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints).
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF3B2416,
    'woodMid': 0xFF6B4423,
    'brass': 0xFFC9A227,
    'brassLight': 0xFFE8CE7A,
    'parchment': 0xFFF1E4C3,
    'parchmentDark': 0xFFDCC99A,
    'ink': 0xFF2A1D10,
    'seaLight': 0xFF2E6E9E,
    'seaDeep': 0xFF12395C,
    'gridLine': 0xFF8FB6D4,
    'hitGlow': 0xFFE0642A,
    'missFoam': 0xFFDFF1F8,
  };

  SeaThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return SeaThemeDef(
      id: 'custom',
      name: 'My Chart',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      brass: c('brass'),
      brassLight: c('brassLight'),
      parchment: c('parchment'),
      parchmentDark: c('parchmentDark'),
      ink: c('ink'),
      seaLight: c('seaLight'),
      seaDeep: c('seaDeep'),
      gridLine: c('gridLine'),
      hitGlow: c('hitGlow'),
      missFoam: c('missFoam'),
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    fleetId = p.getString(_kFleet) ?? 'standard';
    final namesRaw = p.getString(_kNamesJson);
    if (namesRaw != null) {
      playerNames = decodePlayerNames(namesRaw);
    } else {
      final legacy = p.getStringList(_kNames);
      playerNames = (legacy != null && legacy.length == 2)
          ? [for (int i = 0; i < 2; i++) _cleanName(i, legacy[i])]
          : List.of(defaultNames);
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    shipStyle = (p.getInt(_kShipStyle) ?? 0).clamp(0, ShipStyles.names.length - 1);
    wins = p.getInt(_kWins) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestShots = p.getInt(_kBestShots) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] = p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setInt(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kFleet, fleetId);
    await p.setString(_kNamesJson, encodePlayerNames(playerNames));
    await p.remove(_kNames); // drop the legacy unordered key for good
    await p.setString(_kTheme, themeId);
    await p.setInt(_kShipStyle, shipStyle);
    await p.setInt(_kWins, wins);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestShots, bestShots);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || SeaThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (ShipStyles.isPro(shipStyle)) {
      shipStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    final fleet = FleetVariants.byId(fleetId);
    if (fleet.pro) {
      fleetId = 'standard';
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return;
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 1);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // Hard is a Pro feature.
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setFleet(String id) async {
    final f = FleetVariants.byId(id);
    if (!isPro && f.pro) return;
    fleetId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(int index, String name) async {
    if (index < 0 || index > 1) return;
    final clean = name.trim();
    playerNames[index] = clean.isEmpty ? defaultNames[index] : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || SeaThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setShipStyle(int v) async {
    v = v.clamp(0, ShipStyles.names.length - 1);
    if (!isPro && ShipStyles.isPro(v)) return;
    shipStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> recordGame({required bool humanWon, required int shots}) async {
    gamesPlayed++;
    if (humanWon) {
      wins++;
      if (bestShots == 0 || shots < bestShots) bestShots = shots;
    }
    notifyListeners();
    await _save();
  }
}
