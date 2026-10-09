import 'package:flutter/material.dart';

/// Theme, ship-style and fleet catalog for Sea Battle.
///
/// Every theme stays inside the nautical physical-material world (real wood,
/// brass/copper/iron, parchment, ink, sea tones) — the variety comes from
/// different woods, metal accents, chart papers and sea moods. No neon, no
/// cyberpunk, nothing synthetic.
class SeaThemeDef {
  final String id;
  final String name;
  final Color woodDark;
  final Color woodMid;
  final Color brass;
  final Color brassLight;
  final Color parchment;
  final Color parchmentDark;
  final Color ink;
  final Color seaLight;
  final Color seaDeep;
  final Color gridLine;
  final Color hitGlow;
  final Color missFoam;

  const SeaThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.brass,
    required this.brassLight,
    required this.parchment,
    required this.parchmentDark,
    required this.ink,
    required this.seaLight,
    required this.seaDeep,
    required this.gridLine,
    required this.hitGlow,
    required this.missFoam,
  });
}

class SeaThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'mahogany',
    'lagoon',
    'storm',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && byIdOrNull(id) != null;

  static const List<SeaThemeDef> all = [
    SeaThemeDef(
      id: 'classic',
      name: 'Classic Harbor',
      woodDark: Color(0xFF3B2416),
      woodMid: Color(0xFF6B4423),
      brass: Color(0xFFC9A227),
      brassLight: Color(0xFFE8CE7A),
      parchment: Color(0xFFF1E4C3),
      parchmentDark: Color(0xFFDCC99A),
      ink: Color(0xFF2A1D10),
      seaLight: Color(0xFF2E6E9E),
      seaDeep: Color(0xFF12395C),
      gridLine: Color(0xFF8FB6D4),
      hitGlow: Color(0xFFE0642A),
      missFoam: Color(0xFFDFF1F8),
    ),
    SeaThemeDef(
      id: 'mahogany',
      name: "Captain's Quarters",
      woodDark: Color(0xFF401A10),
      woodMid: Color(0xFF6E2F1C),
      brass: Color(0xFFD4AF37),
      brassLight: Color(0xFFF3DC8E),
      parchment: Color(0xFFF6ECD4),
      parchmentDark: Color(0xFFE2CE9E),
      ink: Color(0xFF33150C),
      seaLight: Color(0xFF3A7CA5),
      seaDeep: Color(0xFF173F5F),
      gridLine: Color(0xFF9CC3DE),
      hitGlow: Color(0xFFE2571F),
      missFoam: Color(0xFFE8F4FA),
    ),
    SeaThemeDef(
      id: 'lagoon',
      name: 'Tropical Lagoon',
      woodDark: Color(0xFF4A3418),
      woodMid: Color(0xFF7A5A2E),
      brass: Color(0xFFC9982F),
      brassLight: Color(0xFFF0D68A),
      parchment: Color(0xFFF8F0D8),
      parchmentDark: Color(0xFFE4D4A8),
      ink: Color(0xFF23301A),
      seaLight: Color(0xFF2BB3A3),
      seaDeep: Color(0xFF0E5E66),
      gridLine: Color(0xFFA5E3D8),
      hitGlow: Color(0xFFFF7A3D),
      missFoam: Color(0xFFF2FBF8),
    ),
    SeaThemeDef(
      id: 'storm',
      name: 'Stormy North Sea',
      woodDark: Color(0xFF2B2B30),
      woodMid: Color(0xFF4C4C55),
      brass: Color(0xFF9AA3B2),
      brassLight: Color(0xFFD5DBE5),
      parchment: Color(0xFFE8E4D8),
      parchmentDark: Color(0xFFC9C4B2),
      ink: Color(0xFF1A1C22),
      seaLight: Color(0xFF4A6B8A),
      seaDeep: Color(0xFF1C2E44),
      gridLine: Color(0xFF9FB4C8),
      hitGlow: Color(0xFFFF5A2A),
      missFoam: Color(0xFFE4EDF3),
    ),
    SeaThemeDef(
      id: 'navy',
      name: 'Royal Navy',
      woodDark: Color(0xFF1F2A44),
      woodMid: Color(0xFF33436B),
      brass: Color(0xFFD4AF37),
      brassLight: Color(0xFFF6E27A),
      parchment: Color(0xFFF2EBD6),
      parchmentDark: Color(0xFFDCCFA6),
      ink: Color(0xFF141D33),
      seaLight: Color(0xFF2E5FA3),
      seaDeep: Color(0xFF10294F),
      gridLine: Color(0xFF93B4DE),
      hitGlow: Color(0xFFE8491D),
      missFoam: Color(0xFFEAF2FB),
    ),
    SeaThemeDef(
      id: 'pirate',
      name: 'Pirate Cove',
      woodDark: Color(0xFF241407),
      woodMid: Color(0xFF4A2C12),
      brass: Color(0xFFB08D2E),
      brassLight: Color(0xFFE3C566),
      parchment: Color(0xFFE8D5A8),
      parchmentDark: Color(0xFFC6AC72),
      ink: Color(0xFF1D1206),
      seaLight: Color(0xFF2A7D6B),
      seaDeep: Color(0xFF0F3D36),
      gridLine: Color(0xFF8CC4B4),
      hitGlow: Color(0xFFFF3B1F),
      missFoam: Color(0xFFE6F4EE),
    ),
    SeaThemeDef(
      id: 'abyss',
      name: 'Deep Abyss',
      woodDark: Color(0xFF101828),
      woodMid: Color(0xFF22304A),
      brass: Color(0xFF7FB3C8),
      brassLight: Color(0xFFBFE3F2),
      parchment: Color(0xFFDDE6EE),
      parchmentDark: Color(0xFFB3C2D2),
      ink: Color(0xFF0A1220),
      seaLight: Color(0xFF1E4E6E),
      seaDeep: Color(0xFF081826),
      gridLine: Color(0xFF7FA8C4),
      hitGlow: Color(0xFFFF6A00),
      missFoam: Color(0xFFDCEBF5),
    ),
    SeaThemeDef(
      id: 'arctic',
      name: 'Arctic Voyage',
      woodDark: Color(0xFF3A2E22),
      woodMid: Color(0xFF63503C),
      brass: Color(0xFFC0C6D4),
      brassLight: Color(0xFFE8ECF5),
      parchment: Color(0xFFF4F1E8),
      parchmentDark: Color(0xFFD8D2C0),
      ink: Color(0xFF232B38),
      seaLight: Color(0xFF6FA8C9),
      seaDeep: Color(0xFF2A4E6E),
      gridLine: Color(0xFFC4DCEC),
      hitGlow: Color(0xFFFF7043),
      missFoam: Color(0xFFFFFFFF),
    ),
    SeaThemeDef(
      id: 'sunset',
      name: 'Sunset Regatta',
      woodDark: Color(0xFF4A2418),
      woodMid: Color(0xFF7A4630),
      brass: Color(0xFFE0A83C),
      brassLight: Color(0xFFF8DC9A),
      parchment: Color(0xFFF8E8CC),
      parchmentDark: Color(0xFFE8C89A),
      ink: Color(0xFF3A1E12),
      seaLight: Color(0xFF3E7CA8),
      seaDeep: Color(0xFF27355E),
      gridLine: Color(0xFFB9CCE8),
      hitGlow: Color(0xFFFF4D1C),
      missFoam: Color(0xFFFFF3E0),
    ),
    SeaThemeDef(
      id: 'galleon',
      name: 'Golden Galleon',
      woodDark: Color(0xFF33200E),
      woodMid: Color(0xFF5C3A1A),
      brass: Color(0xFFFFD34D),
      brassLight: Color(0xFFFFE9A8),
      parchment: Color(0xFFF9EFCE),
      parchmentDark: Color(0xFFE6D09A),
      ink: Color(0xFF2E1F08),
      seaLight: Color(0xFF2F6E9E),
      seaDeep: Color(0xFF123A5E),
      gridLine: Color(0xFFA8C6E2),
      hitGlow: Color(0xFFFF5A1A),
      missFoam: Color(0xFFFEF6E0),
    ),
    SeaThemeDef(
      id: 'coral',
      name: 'Coral Reef',
      woodDark: Color(0xFF2E1F16),
      woodMid: Color(0xFF54402E),
      brass: Color(0xFFD98E6A),
      brassLight: Color(0xFFF2BFA0),
      parchment: Color(0xFFF6E9D8),
      parchmentDark: Color(0xFFE3CBB0),
      ink: Color(0xFF33241A),
      seaLight: Color(0xFF3AAFA0),
      seaDeep: Color(0xFF155E58),
      gridLine: Color(0xFFA9DFD4),
      hitGlow: Color(0xFFFF5E3A),
      missFoam: Color(0xFFF0FAF7),
    ),
    SeaThemeDef(
      id: 'ghost',
      name: 'Ghost Ship',
      woodDark: Color(0xFF1A1A24),
      woodMid: Color(0xFF2E2E3C),
      brass: Color(0xFF8FD6C2),
      brassLight: Color(0xFFC9F2E4),
      parchment: Color(0xFFD8DCE4),
      parchmentDark: Color(0xFFAEB4C2),
      ink: Color(0xFF14141C),
      seaLight: Color(0xFF3D5A6E),
      seaDeep: Color(0xFF0E1A26),
      gridLine: Color(0xFF8AA4B8),
      hitGlow: Color(0xFF7CFFD4),
      missFoam: Color(0xFFE2EAF0),
    ),
  ];

  static SeaThemeDef byId(String id, {SeaThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    return byIdOrNull(id) ?? all.first;
  }

  static SeaThemeDef? byIdOrNull(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Ship styles: how each player's fleet is rendered. First 3 are FREE, the
// rest are PRO. The painter (nautical.dart) draws a distinct physical hull
// per style from these material colors.
// ---------------------------------------------------------------------------
class ShipStyleDef {
  final String name;
  final Color hull;
  final Color hullDark;
  final Color sail;
  final Color trim;

  const ShipStyleDef({
    required this.name,
    required this.hull,
    required this.hullDark,
    required this.sail,
    required this.trim,
  });
}

class ShipStyles {
  static const List<String> names = [
    'Oak Galleon', // 0 free
    'Ironclad', // 1 free
    'Viking Longship', // 2 free
    'Pirate Brig', // 3 pro
    'Steam Frigate', // 4 pro
    'Royal Man-o-War', // 5 pro
    'Ghost Ship', // 6 pro
    'Submarine Hunter', // 7 pro
    'Junk Rig', // 8 pro
  ];

  static bool isPro(int i) => i >= 3;

  static const List<ShipStyleDef> all = [
    ShipStyleDef(
      name: 'Oak Galleon',
      hull: Color(0xFF8A5A2B),
      hullDark: Color(0xFF5C3A18),
      sail: Color(0xFFF1E4C3),
      trim: Color(0xFFC9A227),
    ),
    ShipStyleDef(
      name: 'Ironclad',
      hull: Color(0xFF4A4E58),
      hullDark: Color(0xFF2B2E36),
      sail: Color(0xFF8A8F9C),
      trim: Color(0xFFD95F2B),
    ),
    ShipStyleDef(
      name: 'Viking Longship',
      hull: Color(0xFF6E3B1F),
      hullDark: Color(0xFF472512),
      sail: Color(0xFFC0392B),
      trim: Color(0xFFE8CE7A),
    ),
    ShipStyleDef(
      name: 'Pirate Brig',
      hull: Color(0xFF2E1F14),
      hullDark: Color(0xFF180F08),
      sail: Color(0xFF1C1C1C),
      trim: Color(0xFFB08D2E),
    ),
    ShipStyleDef(
      name: 'Steam Frigate',
      hull: Color(0xFF3B3F4A),
      hullDark: Color(0xFF23262E),
      sail: Color(0xFFD8D2C0),
      trim: Color(0xFFC9A227),
    ),
    ShipStyleDef(
      name: 'Royal Man-o-War',
      hull: Color(0xFF1F2A44),
      hullDark: Color(0xFF121A2E),
      sail: Color(0xFFF2EBD6),
      trim: Color(0xFFFFD34D),
    ),
    ShipStyleDef(
      name: 'Ghost Ship',
      hull: Color(0xFF5A6E7E),
      hullDark: Color(0xFF39454E),
      sail: Color(0xFFD8DCE4),
      trim: Color(0xFF8FD6C2),
    ),
    ShipStyleDef(
      name: 'Submarine Hunter',
      hull: Color(0xFF2E4A3E),
      hullDark: Color(0xFF1B2E26),
      sail: Color(0xFF9CC3B4),
      trim: Color(0xFFE0642A),
    ),
    ShipStyleDef(
      name: 'Junk Rig',
      hull: Color(0xFF7A2E1F),
      hullDark: Color(0xFF4E1D12),
      sail: Color(0xFFD9A441),
      trim: Color(0xFF2E1F14),
    ),
  ];

  static ShipStyleDef of(int i) => all[i.clamp(0, all.length - 1)];
}

// ---------------------------------------------------------------------------
// Fleet variants (RULES.md §2). All play on the 10x10 chart.
// ---------------------------------------------------------------------------
class FleetVariant {
  final String id;
  final String name;
  final List<int> ships; // ship lengths
  final bool pro;

  const FleetVariant({
    required this.id,
    required this.name,
    required this.ships,
    this.pro = false,
  });

  int get totalCells => ships.fold(0, (a, b) => a + b);
}

class FleetVariants {
  static const List<FleetVariant> all = [
    FleetVariant(
      id: 'standard',
      name: 'Standard Fleet',
      ships: [5, 4, 3, 3, 2],
    ),
    FleetVariant(
      id: 'skirmish',
      name: 'Quick Skirmish',
      ships: [4, 3, 2],
    ),
    FleetVariant(
      id: 'armada',
      name: 'Grand Armada',
      ships: [6, 5, 4, 3, 3, 2],
      pro: true,
    ),
  ];

  static FleetVariant byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return all.first;
  }
}

/// Classic ship names by length, for sunk narration (RULES.md §9).
String shipNameFor(int length) => switch (length) {
      6 => 'Dreadnought',
      5 => 'Carrier',
      4 => 'Battleship',
      3 => 'Cruiser',
      2 => 'Destroyer',
      _ => 'Patrol Boat',
    };
