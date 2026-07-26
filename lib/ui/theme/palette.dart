import 'package:flutter/material.dart';

/// A fully-resolved set of colors for one scheme at one brightness.
///
/// Digit colors are stored as **final cell fill colors**, not tints to be
/// alpha-blended at paint time. v1 blended a base color over the surface at
/// 20-45% opacity, which desaturated it -- the reason reds read as maroon.
/// Specifying the end color directly gives each scheme exact control, and is
/// what makes a high-saturation neon look possible at all.
@immutable
class Palette {
  final Color background;
  final Color surface;
  final Color gridLine;
  final Color boxLine;
  final Color givenText;
  final Color userText;
  final Color noteText;
  final Color errorText;
  final Color errorCell;
  final Color selectedCell;
  final Color peerCell;

  /// Ring drawn around the selected cell. Used instead of recoloring the cell
  /// so a filled cell keeps its digit color while still reading as selected.
  final Color selectionRing;

  /// Scrim laid over a *filled* peer cell to echo the row/col/box highlight
  /// without destroying the digit's fill color.
  final Color peerScrim;

  final Color primary;
  final Color hintCell;

  /// Cell background per digit, 1-6.
  final Map<int, Color> digitFills;

  /// Text color that sits on top of the matching [digitFills] entry.
  final Map<int, Color> digitTextColors;

  const Palette({
    required this.background,
    required this.surface,
    required this.gridLine,
    required this.boxLine,
    required this.givenText,
    required this.userText,
    required this.noteText,
    required this.errorText,
    required this.errorCell,
    required this.selectedCell,
    required this.peerCell,
    required this.selectionRing,
    required this.peerScrim,
    required this.primary,
    required this.hintCell,
    required this.digitFills,
    required this.digitTextColors,
  });

  Color fillFor(int digit) => digitFills[digit] ?? surface;
  Color textOn(int digit) => digitTextColors[digit] ?? givenText;
}

/// A named scheme with both brightness variants, so the user's light/dark/system
/// preference stays orthogonal to their color-scheme preference.
@immutable
class PaletteScheme {
  final String id;
  final String name;
  final String description;
  final Palette light;
  final Palette dark;

  const PaletteScheme({
    required this.id,
    required this.name,
    required this.description,
    required this.light,
    required this.dark,
  });

  Palette forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;
}

// ---------------------------------------------------------------------------
// Retro-Futuristic (default) -- synthwave / outrun
// ---------------------------------------------------------------------------

const _retroDark = Palette(
  background: Color(0xFF0A0518),
  surface: Color(0xFF150B2B),
  gridLine: Color(0xFF2D1B4E),
  boxLine: Color(0xFF00E5FF),
  givenText: Color(0xFFEDE7FF),
  userText: Color(0xFF00E5FF),
  noteText: Color(0xFF9B8DC4),
  errorText: Color(0xFFFF2E63),
  errorCell: Color(0xFF3D0A1E),
  selectedCell: Color(0xFF351C63),
  peerCell: Color(0xFF261445),
  selectionRing: Color(0xFF00E5FF),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFFF2E9F),
  hintCell: Color(0xFF3A1A5C),
  digitFills: {
    1: Color(0xFFFFC400),
    2: Color(0xFFFF1744),
    3: Color(0xFF00B0FF),
    4: Color(0xFF00E676),
    5: Color(0xFFAA00FF),
    6: Color(0xFFFF6D00),
  },
  digitTextColors: {
    1: Color(0xFF1A0A00),
    2: Color(0xFF2A0009),
    3: Color(0xFF041423),
    4: Color(0xFF00220F),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF1F0A00),
  },
);

const _retroLight = Palette(
  background: Color(0xFFFDF4FF),
  surface: Color(0xFFFFFFFF),
  gridLine: Color(0xFFE8D5F2),
  boxLine: Color(0xFF6A1B9A),
  givenText: Color(0xFF1A0B2E),
  userText: Color(0xFF7B1FA2),
  noteText: Color(0xFF8E7BA6),
  errorText: Color(0xFFC2185B),
  errorCell: Color(0xFFFCE4EC),
  selectedCell: Color(0xFFF3D9FF),
  peerCell: Color(0xFFFAF0FF),
  selectionRing: Color(0xFF7B1FA2),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFD500F9),
  hintCell: Color(0xFFEDD4FA),
  digitFills: {
    1: Color(0xFFFFB300),
    2: Color(0xFFF50057),
    3: Color(0xFF2979FF),
    4: Color(0xFF00C853),
    5: Color(0xFF9C27B0),
    6: Color(0xFFFF6D00),
  },
  digitTextColors: {
    1: Color(0xFF3E2600),
    2: Color(0xFFFFFFFF),
    3: Color(0xFF04122E),
    4: Color(0xFF002E12),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF331500),
  },
);

// ---------------------------------------------------------------------------
// Modern -- clean, high contrast
// ---------------------------------------------------------------------------

const _modernDark = Palette(
  background: Color(0xFF101014),
  surface: Color(0xFF1C1C22),
  gridLine: Color(0xFF2E2E36),
  boxLine: Color(0xFFB4B4C0),
  givenText: Color(0xFFF2F2F5),
  userText: Color(0xFF7EA6FF),
  noteText: Color(0xFF8A8A99),
  errorText: Color(0xFFFF6B60),
  errorCell: Color(0xFF3B2226),
  selectedCell: Color(0xFF2C3550),
  peerCell: Color(0xFF23232B),
  selectionRing: Color(0xFF7EA6FF),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFF5B8DEF),
  hintCell: Color(0xFF33405F),
  digitFills: {
    1: Color(0xFFF2C037),
    2: Color(0xFFE4494F),
    3: Color(0xFF3B82F6),
    4: Color(0xFF22A65C),
    5: Color(0xFF8B5CF6),
    6: Color(0xFFEE7B30),
  },
  digitTextColors: {
    1: Color(0xFF241B00),
    2: Color(0xFF2E0507),
    3: Color(0xFF04122E),
    4: Color(0xFF002012),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2A1200),
  },
);

const _modernLight = Palette(
  background: Color(0xFFF7F8FA),
  surface: Color(0xFFFFFFFF),
  gridLine: Color(0xFFE0E2E7),
  boxLine: Color(0xFF2B2F38),
  givenText: Color(0xFF1B1D23),
  userText: Color(0xFF2563EB),
  noteText: Color(0xFF8A8F9A),
  errorText: Color(0xFFD8453B),
  errorCell: Color(0xFFFDE7E5),
  selectedCell: Color(0xFFDDE3FF),
  peerCell: Color(0xFFF0F1F5),
  selectionRing: Color(0xFF2563EB),
  peerScrim: Color(0x14000000),
  primary: Color(0xFF3D5AFE),
  hintCell: Color(0xFFD6DEFF),
  digitFills: {
    1: Color(0xFFEAB308),
    2: Color(0xFFDC2626),
    3: Color(0xFF2563EB),
    4: Color(0xFF16A34A),
    5: Color(0xFF7C3AED),
    6: Color(0xFFEA580C),
  },
  digitTextColors: {
    1: Color(0xFF2E2100),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFF00250F),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2E1000),
  },
);

// ---------------------------------------------------------------------------
// Post-Modern -- flat Memphis / Bauhaus, heavy lines, cream ground
// ---------------------------------------------------------------------------

const _postModernLight = Palette(
  background: Color(0xFFF5F0E6),
  surface: Color(0xFFFFFDF7),
  gridLine: Color(0xFFD8D0C0),
  boxLine: Color(0xFF111111),
  givenText: Color(0xFF111111),
  userText: Color(0xFFE63946),
  noteText: Color(0xFF8C8375),
  errorText: Color(0xFFC1121F),
  errorCell: Color(0xFFF7DAD9),
  selectedCell: Color(0xFFFFE8A3),
  peerCell: Color(0xFFEDE6D8),
  selectionRing: Color(0xFF111111),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFE63946),
  hintCell: Color(0xFFB8E0D2),
  digitFills: {
    1: Color(0xFFF7D002),
    2: Color(0xFFE63946),
    3: Color(0xFF1D3557),
    4: Color(0xFF2A9D8F),
    5: Color(0xFF6D4C9F),
    6: Color(0xFFF4802A),
  },
  digitTextColors: {
    1: Color(0xFF241F00),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFF00201C),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2E1400),
  },
);

const _postModernDark = Palette(
  background: Color(0xFF1A1A1A),
  surface: Color(0xFF242424),
  gridLine: Color(0xFF3A3A3A),
  boxLine: Color(0xFFE8E4DA),
  givenText: Color(0xFFF2EFE6),
  userText: Color(0xFFFF6B6B),
  noteText: Color(0xFF8F8A80),
  errorText: Color(0xFFFF6B6B),
  errorCell: Color(0xFF3D2020),
  selectedCell: Color(0xFF4A4020),
  peerCell: Color(0xFF2E2E2E),
  selectionRing: Color(0xFFE8E4DA),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFE63946),
  hintCell: Color(0xFF1F4A42),
  digitFills: {
    1: Color(0xFFF7D002),
    2: Color(0xFFE63946),
    3: Color(0xFF3E6EA8),
    4: Color(0xFF2A9D8F),
    5: Color(0xFF8A63C4),
    6: Color(0xFFF4802A),
  },
  digitTextColors: {
    1: Color(0xFF241F00),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFF00201C),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2E1400),
  },
);

// ---------------------------------------------------------------------------
// Apocalyptic -- rust, ash, warning amber, toxic green
// ---------------------------------------------------------------------------

const _apocalypticDark = Palette(
  background: Color(0xFF12100D),
  surface: Color(0xFF1E1A15),
  gridLine: Color(0xFF332C22),
  boxLine: Color(0xFFA6551F),
  givenText: Color(0xFFE8DFD0),
  userText: Color(0xFFE8B21E),
  noteText: Color(0xFF8A7D68),
  errorText: Color(0xFFFF5722),
  errorCell: Color(0xFF3B1A10),
  selectedCell: Color(0xFF3A2E1C),
  peerCell: Color(0xFF272219),
  selectionRing: Color(0xFFE8B21E),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFD2321B),
  hintCell: Color(0xFF3E3418),
  digitFills: {
    1: Color(0xFFE8B21E),
    2: Color(0xFFD2321B),
    3: Color(0xFF4E88A8),
    4: Color(0xFF8FBF2E),
    5: Color(0xFF8B5A9B),
    6: Color(0xFFE07316),
  },
  digitTextColors: {
    1: Color(0xFF241A00),
    2: Color(0xFFFFFFFF),
    3: Color(0xFF04161F),
    4: Color(0xFF16200A),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2A1300),
  },
);

const _apocalypticLight = Palette(
  background: Color(0xFFE8E0D2),
  surface: Color(0xFFF5EFE3),
  gridLine: Color(0xFFCFC4B0),
  boxLine: Color(0xFF6B4226),
  givenText: Color(0xFF2B2318),
  userText: Color(0xFF9A4B12),
  noteText: Color(0xFF8A7F6C),
  errorText: Color(0xFFB3301C),
  errorCell: Color(0xFFF0D5CB),
  selectedCell: Color(0xFFE0CFA8),
  peerCell: Color(0xFFDED6C6),
  selectionRing: Color(0xFF6B4226),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFB3301C),
  hintCell: Color(0xFFCFD9AE),
  digitFills: {
    1: Color(0xFFD49A0E),
    2: Color(0xFFB3301C),
    3: Color(0xFF3E6E88),
    4: Color(0xFF6B8E23),
    5: Color(0xFF6E4B7E),
    6: Color(0xFFC4600F),
  },
  digitTextColors: {
    1: Color(0xFF2B1E00),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFF16200A),
    5: Color(0xFFFFFFFF),
    6: Color(0xFFFFFFFF),
  },
);

// ---------------------------------------------------------------------------
// Classic -- v1 colors, preserved exactly.
// Fills are the precomputed result of v1's blend (0.20 over white in light,
// 0.45 over #1E2027 in dark) so this scheme is pixel-faithful to the original.
// ---------------------------------------------------------------------------

const _classicLight = Palette(
  background: Color(0xFFF7F8FA),
  surface: Color(0xFFFFFFFF),
  gridLine: Color(0xFFE0E2E7),
  boxLine: Color(0xFF2B2F38),
  givenText: Color(0xFF1B1D23),
  userText: Color(0xFF3D5AFE),
  noteText: Color(0xFF8A8F9A),
  errorText: Color(0xFFD8453B),
  errorCell: Color(0xFFFDE7E5),
  selectedCell: Color(0xFFDDE3FF),
  peerCell: Color(0xFFF0F1F5),
  selectionRing: Color(0xFF3D5AFE),
  peerScrim: Color(0x0F000000),
  primary: Color(0xFF3D5AFE),
  hintCell: Color(0xFFD6DEFF),
  digitFills: {
    1: Color(0xFFFEF2D5),
    2: Color(0xFFFAD7D7),
    3: Color(0xFFD2E7FA),
    4: Color(0xFFD9ECDA),
    5: Color(0xFFE8D3EE),
    6: Color(0xFFFEE8CC),
  },
  digitTextColors: {
    1: Color(0xFF1B1D23),
    2: Color(0xFF1B1D23),
    3: Color(0xFF1B1D23),
    4: Color(0xFF1B1D23),
    5: Color(0xFF1B1D23),
    6: Color(0xFF1B1D23),
  },
);

const _classicDark = Palette(
  background: Color(0xFF15161B),
  surface: Color(0xFF1E2027),
  gridLine: Color(0xFF33353E),
  boxLine: Color(0xFFB8BCC8),
  givenText: Color(0xFFEDEEF2),
  userText: Color(0xFF8C9CFF),
  noteText: Color(0xFF8A8F9A),
  errorText: Color(0xFFFF6B60),
  errorCell: Color(0xFF3B2226),
  selectedCell: Color(0xFF33395C),
  peerCell: Color(0xFF23252D),
  selectionRing: Color(0xFF8C9CFF),
  peerScrim: Color(0x14FFFFFF),
  primary: Color(0xFF7C8CFF),
  hintCell: Color(0xFF33395C),
  digitFills: {
    1: Color(0xFF81682A),
    2: Color(0xFF782B2D),
    3: Color(0xFF1E4F7C),
    4: Color(0xFF2F5A35),
    5: Color(0xFF502262),
    6: Color(0xFF815115),
  },
  digitTextColors: {
    1: Color(0xFFEDEEF2),
    2: Color(0xFFEDEEF2),
    3: Color(0xFFEDEEF2),
    4: Color(0xFFEDEEF2),
    5: Color(0xFFEDEEF2),
    6: Color(0xFFEDEEF2),
  },
);

// ---------------------------------------------------------------------------

class AppPalettes {
  AppPalettes._();

  static const retro = PaletteScheme(
    id: 'retro',
    name: 'Retro-Futuristic',
    description: 'Neon synthwave on deep indigo',
    light: _retroLight,
    dark: _retroDark,
  );

  static const modern = PaletteScheme(
    id: 'modern',
    name: 'Modern',
    description: 'Clean and high contrast',
    light: _modernLight,
    dark: _modernDark,
  );

  static const postModern = PaletteScheme(
    id: 'postmodern',
    name: 'Post-Modern',
    description: 'Flat Memphis shapes on cream',
    light: _postModernLight,
    dark: _postModernDark,
  );

  static const apocalyptic = PaletteScheme(
    id: 'apocalyptic',
    name: 'Apocalyptic',
    description: 'Rust, ash and warning amber',
    light: _apocalypticLight,
    dark: _apocalypticDark,
  );

  static const classic = PaletteScheme(
    id: 'classic',
    name: 'Classic',
    description: 'The original muted palette',
    light: _classicLight,
    dark: _classicDark,
  );

  static const defaultId = 'retro';

  static const all = <PaletteScheme>[
    retro,
    modern,
    postModern,
    apocalyptic,
    classic,
  ];

  static PaletteScheme byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => retro);
}

/// Carries the resolved [Palette] on [ThemeData] so widgets pick up the right
/// brightness variant automatically -- including under `ThemeMode.system` --
/// without duplicating light/dark resolution logic at each call site.
@immutable
class PaletteExtension extends ThemeExtension<PaletteExtension> {
  final Palette palette;

  const PaletteExtension(this.palette);

  @override
  PaletteExtension copyWith({Palette? palette}) =>
      PaletteExtension(palette ?? this.palette);

  // Palettes switch discretely; there is nothing meaningful to interpolate.
  @override
  PaletteExtension lerp(covariant ThemeExtension<PaletteExtension>? other, double t) =>
      t < 0.5 ? this : (other as PaletteExtension? ?? this);
}

extension PaletteContext on BuildContext {
  Palette get palette =>
      Theme.of(this).extension<PaletteExtension>()?.palette ?? _retroDark;
}
