import 'package:flutter/material.dart';

/// A fully-resolved set of colors for one scheme at one brightness.
///
/// Digit colors are stored as **final cell fill colors**, not tints to be
/// alpha-blended at paint time. v1 blended a base color over the surface at
/// 20-45% opacity, which desaturated it -- the reason reds read as maroon.
/// Specifying the end color directly gives each scheme exact control, and is
/// what makes a high-saturation neon look possible at all.
///
/// Scheme design rule, learned the hard way: themes that differ only in
/// digit saturation on the same near-black background all read as the same
/// theme. Every scheme here commits to its own background hue, its own seam
/// color, and its own digit strategy (neon, CRT-bright, bioluminescent,
/// fire-and-ash, pastel-on-ink...), so switching schemes visibly changes the
/// whole game, not just the six squares.
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
// Terminal (id 'modern') -- phosphor CRT on pure black
// ---------------------------------------------------------------------------

const _terminalDark = Palette(
  background: Color(0xFF000000),
  surface: Color(0xFF0A120A),
  gridLine: Color(0xFF1C2E1C),
  boxLine: Color(0xFF33FF66),
  givenText: Color(0xFFD6FFD6),
  userText: Color(0xFF33FF66),
  noteText: Color(0xFF5E9A6C),
  errorText: Color(0xFFFF5252),
  errorCell: Color(0xFF2E0D0D),
  selectedCell: Color(0xFF123A1E),
  peerCell: Color(0xFF0A1F0E),
  selectionRing: Color(0xFF33FF66),
  peerScrim: Color(0x2033FF66),
  primary: Color(0xFF33FF66),
  hintCell: Color(0xFF153D22),
  digitFills: {
    1: Color(0xFFFFD400),
    2: Color(0xFFFF4747),
    3: Color(0xFF35CCFF),
    4: Color(0xFF33FF66),
    5: Color(0xFFCC66FF),
    6: Color(0xFFFF9933),
  },
  digitTextColors: {
    1: Color(0xFF201700),
    2: Color(0xFF2A0303),
    3: Color(0xFF03202E),
    4: Color(0xFF002211),
    5: Color(0xFF24063A),
    6: Color(0xFF251200),
  },
);

const _terminalLight = Palette(
  background: Color(0xFFEAF2EA),
  surface: Color(0xFFF8FCF8),
  gridLine: Color(0xFFC7D8C7),
  boxLine: Color(0xFF1B5E20),
  givenText: Color(0xFF0F2911),
  userText: Color(0xFF1B5E20),
  noteText: Color(0xFF6C846C),
  errorText: Color(0xFFC62828),
  errorCell: Color(0xFFF5DBDB),
  selectedCell: Color(0xFFCFE8CF),
  peerCell: Color(0xFFDFEDDF),
  selectionRing: Color(0xFF1B5E20),
  peerScrim: Color(0x14000000),
  primary: Color(0xFF1B5E20),
  hintCell: Color(0xFFC9E6C9),
  digitFills: {
    1: Color(0xFFE6A800),
    2: Color(0xFFC62828),
    3: Color(0xFF1565C0),
    4: Color(0xFF2E7D32),
    5: Color(0xFF6A1B9A),
    6: Color(0xFFE65100),
  },
  digitTextColors: {
    1: Color(0xFF231A00),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2E1300),
  },
);

// ---------------------------------------------------------------------------
// Deep Sea (id 'postmodern') -- bioluminescence in dark water
// ---------------------------------------------------------------------------

const _deepSeaDark = Palette(
  background: Color(0xFF041B26),
  surface: Color(0xFF0A2836),
  gridLine: Color(0xFF14404F),
  boxLine: Color(0xFF4DD0E1),
  givenText: Color(0xFFE0F7FA),
  userText: Color(0xFF4DD0E1),
  noteText: Color(0xFF6FA3B0),
  errorText: Color(0xFFFF7043),
  errorCell: Color(0xFF3B1A10),
  selectedCell: Color(0xFF14506A),
  peerCell: Color(0xFF0D3140),
  selectionRing: Color(0xFF4DD0E1),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFF26C6DA),
  hintCell: Color(0xFF0F4C5C),
  digitFills: {
    1: Color(0xFFFFD54F),
    2: Color(0xFFFF6B6B),
    3: Color(0xFF29B6F6),
    4: Color(0xFF26A69A),
    5: Color(0xFF9575CD),
    6: Color(0xFFFFA726),
  },
  digitTextColors: {
    1: Color(0xFF241B00),
    2: Color(0xFF330808),
    3: Color(0xFF032235),
    4: Color(0xFF00201C),
    5: Color(0xFF1E1240),
    6: Color(0xFF241300),
  },
);

const _deepSeaLight = Palette(
  background: Color(0xFFE3F1F5),
  surface: Color(0xFFF4FAFC),
  gridLine: Color(0xFFBFDBE2),
  boxLine: Color(0xFF0E4A5C),
  givenText: Color(0xFF0B2E38),
  userText: Color(0xFF00838F),
  noteText: Color(0xFF5E858F),
  errorText: Color(0xFFD84315),
  errorCell: Color(0xFFF8DCD2),
  selectedCell: Color(0xFFC2E5EC),
  peerCell: Color(0xFFD8EBF0),
  selectionRing: Color(0xFF00838F),
  peerScrim: Color(0x14000000),
  primary: Color(0xFF00838F),
  hintCell: Color(0xFFBCE2E9),
  digitFills: {
    1: Color(0xFFF0B90B),
    2: Color(0xFFE4584B),
    3: Color(0xFF1976D2),
    4: Color(0xFF00897B),
    5: Color(0xFF7E57C2),
    6: Color(0xFFF57C00),
  },
  digitTextColors: {
    1: Color(0xFF231B00),
    2: Color(0xFF330B05),
    3: Color(0xFFFFFFFF),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFFFFF),
    6: Color(0xFF2A1500),
  },
);

// ---------------------------------------------------------------------------
// Ember (id 'apocalyptic') -- fire and ash on charred ground
// ---------------------------------------------------------------------------

const _emberDark = Palette(
  background: Color(0xFF150A04),
  surface: Color(0xFF241108),
  gridLine: Color(0xFF40250F),
  boxLine: Color(0xFFFF6D00),
  givenText: Color(0xFFFFE9D6),
  userText: Color(0xFFFFB74D),
  noteText: Color(0xFFA98A70),
  errorText: Color(0xFFFF5252),
  errorCell: Color(0xFF3D1512),
  selectedCell: Color(0xFF4A2410),
  peerCell: Color(0xFF2E1809),
  selectionRing: Color(0xFFFFB74D),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFFF6D00),
  hintCell: Color(0xFF45300F),
  digitFills: {
    1: Color(0xFFFFC400),
    2: Color(0xFFE5322E),
    3: Color(0xFF41616F),
    4: Color(0xFFAEEA00),
    5: Color(0xFF6D4C7D),
    6: Color(0xFFFF8F00),
  },
  digitTextColors: {
    1: Color(0xFF241A00),
    2: Color(0xFF310404),
    3: Color(0xFFEDF5F8),
    4: Color(0xFF1C2600),
    5: Color(0xFFF4EAF8),
    6: Color(0xFF251300),
  },
);

const _emberLight = Palette(
  background: Color(0xFFF2E2C4),
  surface: Color(0xFFFAF0DC),
  gridLine: Color(0xFFD9C098),
  boxLine: Color(0xFF7A2E0E),
  givenText: Color(0xFF33200E),
  userText: Color(0xFFB23A12),
  noteText: Color(0xFF927554),
  errorText: Color(0xFFB3261E),
  errorCell: Color(0xFFF2D4CE),
  selectedCell: Color(0xFFEACF98),
  peerCell: Color(0xFFEDDDB9),
  selectionRing: Color(0xFF7A2E0E),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFB23A12),
  hintCell: Color(0xFFE2D08F),
  digitFills: {
    1: Color(0xFFD99A06),
    2: Color(0xFFB3261E),
    3: Color(0xFF3E6273),
    4: Color(0xFF5F7317),
    5: Color(0xFF6D4C7D),
    6: Color(0xFFC05B0D),
  },
  digitTextColors: {
    1: Color(0xFF2A1D00),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFFFFF),
    6: Color(0xFFFFFFFF),
  },
);

// ---------------------------------------------------------------------------
// Blossom (id 'blossom') -- pastel petals by day, plum night after dark
// ---------------------------------------------------------------------------

const _blossomLight = Palette(
  background: Color(0xFFFFF4F7),
  surface: Color(0xFFFFFFFF),
  gridLine: Color(0xFFF0D5DD),
  boxLine: Color(0xFFAD1457),
  givenText: Color(0xFF3A1B27),
  userText: Color(0xFFC2185B),
  noteText: Color(0xFFA88793),
  errorText: Color(0xFFC62828),
  errorCell: Color(0xFFFBE0E0),
  selectedCell: Color(0xFFFBD9E4),
  peerCell: Color(0xFFFBEEF2),
  selectionRing: Color(0xFFC2185B),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFEC407A),
  hintCell: Color(0xFFF7CFDE),
  digitFills: {
    1: Color(0xFFFFE082),
    2: Color(0xFFF48FB1),
    3: Color(0xFF90CAF9),
    4: Color(0xFFA5D6A7),
    5: Color(0xFFCE93D8),
    6: Color(0xFFFFCC80),
  },
  digitTextColors: {
    1: Color(0xFF2E2200),
    2: Color(0xFF3A0E1E),
    3: Color(0xFF0A2A45),
    4: Color(0xFF123A16),
    5: Color(0xFF2E0E38),
    6: Color(0xFF331A00),
  },
);

const _blossomDark = Palette(
  background: Color(0xFF1C0F1A),
  surface: Color(0xFF2A1727),
  gridLine: Color(0xFF45283C),
  boxLine: Color(0xFFF48FB1),
  givenText: Color(0xFFFCE4EC),
  userText: Color(0xFFF48FB1),
  noteText: Color(0xFFA98598),
  errorText: Color(0xFFFF6B60),
  errorCell: Color(0xFF3D1620),
  selectedCell: Color(0xFF4A2440),
  peerCell: Color(0xFF341C2F),
  selectionRing: Color(0xFFF48FB1),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFF06292),
  hintCell: Color(0xFF45213A),
  // Pastels carry to the dark variant on purpose: soft fills on deep plum is
  // the scheme's identity, and the same paired ink texts stay readable on
  // both brightnesses.
  digitFills: {
    1: Color(0xFFFFE082),
    2: Color(0xFFF48FB1),
    3: Color(0xFF90CAF9),
    4: Color(0xFFA5D6A7),
    5: Color(0xFFCE93D8),
    6: Color(0xFFFFCC80),
  },
  digitTextColors: {
    1: Color(0xFF2E2200),
    2: Color(0xFF3A0E1E),
    3: Color(0xFF0A2A45),
    4: Color(0xFF123A16),
    5: Color(0xFF2E0E38),
    6: Color(0xFF331A00),
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

  // Ids for these three predate their redesign ('modern', 'postmodern',
  // 'apocalyptic') and are what existing installs have saved in Hive, so the
  // ids stay put while the look and display name move on.
  static const terminal = PaletteScheme(
    id: 'modern',
    name: 'Terminal',
    description: 'Phosphor CRT on pure black',
    light: _terminalLight,
    dark: _terminalDark,
  );

  static const deepSea = PaletteScheme(
    id: 'postmodern',
    name: 'Deep Sea',
    description: 'Bioluminescence in dark water',
    light: _deepSeaLight,
    dark: _deepSeaDark,
  );

  static const ember = PaletteScheme(
    id: 'apocalyptic',
    name: 'Ember',
    description: 'Fire and ash on charred ground',
    light: _emberLight,
    dark: _emberDark,
  );

  static const blossom = PaletteScheme(
    id: 'blossom',
    name: 'Blossom',
    description: 'Pastel petals, plum nights',
    light: _blossomLight,
    dark: _blossomDark,
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
    terminal,
    deepSea,
    ember,
    blossom,
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
