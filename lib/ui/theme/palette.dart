import 'package:flutter/material.dart';

/// A fully-resolved set of colors for one scheme at one brightness.
///
/// Digit colors are stored as **final cell fill colors**, not tints to be
/// alpha-blended at paint time. v1 blended a base color over the surface at
/// 20-45% opacity, which desaturated it -- the reason reds read as maroon.
/// Specifying the end color directly gives each scheme exact control, and is
/// what makes a high-saturation neon look possible at all.
///
/// Scheme design rule, learned twice: themes that differ only in digit
/// saturation on the same near-black background all read as the same theme.
/// The second lesson was subtler -- keeping 1=yellow, 2=red ... 6=orange in
/// every scheme meant even schemes with distinct backgrounds were still the
/// same palette wearing a different jacket. **The digit-to-hue mapping is per
/// scheme, not global.** v1's mapping survives only in Retro-Futuristic and
/// Classic; everything else picks its own color *system* -- a luminance ramp,
/// a graphic primary set, a thermal gradient.
///
/// The two things a scheme may not trade away: six fills a player can tell
/// apart at a glance, and text that clears ~4.0 contrast on its own fill.
///
/// Note that the Wordle-style share text stays on v1's emoji mapping
/// regardless of scheme (see utils/share_text.dart). It is read by people who
/// may be on another theme entirely, so it has to be fixed notation rather
/// than a mirror of the sender's board.
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
// Retro-Futuristic (default) -- synthwave / outrun.
// The one scheme that keeps v1's digit-to-hue mapping, because it is the
// mapping: neon yellow/red/blue/green/purple/orange is the look.
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
// Slate (id 'modern') -- monochrome, digits read by weight.
//
// Six steps of one cool grey instead of six hues. Besides being the most
// literally "modern" of the set, encoding digits by luminance rather than hue
// is the only scheme here that survives red-green color blindness intact --
// the retro palette's 2/4 pair is exactly the hard case.
// ---------------------------------------------------------------------------

const _slateDark = Palette(
  background: Color(0xFF07090C),
  surface: Color(0xFF10161D),
  gridLine: Color(0xFF1C2630),
  boxLine: Color(0xFF7C8FA3),
  givenText: Color(0xFFE6EDF3),
  userText: Color(0xFF9FB4C8),
  noteText: Color(0xFF6B7C8C),
  errorText: Color(0xFFF87171),
  errorCell: Color(0xFF3A1D1D),
  selectedCell: Color(0xFF1E2C38),
  peerCell: Color(0xFF141C24),
  selectionRing: Color(0xFF9FB4C8),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFF94A3B8),
  hintCell: Color(0xFF24333F),
  digitFills: {
    1: Color(0xFFF1F5F9),
    2: Color(0xFFC7D2DC),
    3: Color(0xFF9AAAB8),
    4: Color(0xFF5D7286),
    5: Color(0xFF40525F),
    6: Color(0xFF1F2C36),
  },
  digitTextColors: {
    1: Color(0xFF0B1117),
    2: Color(0xFF0B1117),
    3: Color(0xFF0B1117),
    4: Color(0xFFEAF0F6),
    5: Color(0xFFEAF0F6),
    6: Color(0xFFEAF0F6),
  },
);

const _slateLight = Palette(
  background: Color(0xFFF7F9FB),
  surface: Color(0xFFFFFFFF),
  gridLine: Color(0xFFD8E0E8),
  boxLine: Color(0xFF55677A),
  givenText: Color(0xFF1B2733),
  userText: Color(0xFF3F5568),
  noteText: Color(0xFF7C8B9A),
  errorText: Color(0xFFC0392B),
  errorCell: Color(0xFFFBE4E1),
  selectedCell: Color(0xFFDDE6EE),
  peerCell: Color(0xFFEEF3F7),
  selectionRing: Color(0xFF3F5568),
  peerScrim: Color(0x14000000),
  primary: Color(0xFF47586B),
  hintCell: Color(0xFFD2DEE9),
  digitFills: {
    1: Color(0xFFD7E0E9),
    2: Color(0xFFB3C1CE),
    3: Color(0xFF8E9FB0),
    4: Color(0xFF6A7C8E),
    5: Color(0xFF4A5A6B),
    6: Color(0xFF2B3A49),
  },
  digitTextColors: {
    1: Color(0xFF1F2933),
    2: Color(0xFF1F2933),
    3: Color(0xFF0F1720),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFFFFF),
    6: Color(0xFFFFFFFF),
  },
);

// ---------------------------------------------------------------------------
// Bauhaus (id 'postmodern') -- graphic primaries, heavy black rules.
//
// A poster rather than a screen: flat primaries on bone paper, with the box
// seams doing the work a black keyline does in Swiss layout. Replaces Deep
// Sea, which was distinct in mood but still ran v1's six hues underneath.
// ---------------------------------------------------------------------------

const _bauhausLight = Palette(
  background: Color(0xFFF2EFE6),
  surface: Color(0xFFFBF9F3),
  gridLine: Color(0xFFDCD7C8),
  boxLine: Color(0xFF111111),
  givenText: Color(0xFF14140F),
  userText: Color(0xFFD1372B),
  noteText: Color(0xFF8A8578),
  errorText: Color(0xFFD1372B),
  errorCell: Color(0xFFF7DDD9),
  selectedCell: Color(0xFFFFE9A8),
  peerCell: Color(0xFFEAE6D9),
  selectionRing: Color(0xFF111111),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFD1372B),
  hintCell: Color(0xFFFFE0A0),
  digitFills: {
    1: Color(0xFFF2B705),
    2: Color(0xFFD1372B),
    3: Color(0xFF1E4C8A),
    4: Color(0xFF2E8B6F),
    5: Color(0xFF1A1A1A),
    6: Color(0xFFE2714C),
  },
  digitTextColors: {
    1: Color(0xFF1A1400),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFF2EFE6),
    6: Color(0xFF23100A),
  },
);

const _bauhausDark = Palette(
  background: Color(0xFF121212),
  surface: Color(0xFF1B1B1B),
  gridLine: Color(0xFF2E2E2E),
  boxLine: Color(0xFFF2EFE6),
  givenText: Color(0xFFF2EFE6),
  userText: Color(0xFFFFC629),
  noteText: Color(0xFF8A8578),
  errorText: Color(0xFFE03A22),
  errorCell: Color(0xFF3A1410),
  selectedCell: Color(0xFF33301F),
  peerCell: Color(0xFF202020),
  selectionRing: Color(0xFFF2EFE6),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFFFC629),
  hintCell: Color(0xFF3D3820),
  digitFills: {
    1: Color(0xFFFFC629),
    2: Color(0xFFE03A22),
    3: Color(0xFF2C6BC4),
    4: Color(0xFF35A67F),
    5: Color(0xFFF2EFE6),
    6: Color(0xFFF58A5B),
  },
  digitTextColors: {
    1: Color(0xFF1A1400),
    2: Color(0xFFFFFFFF),
    3: Color(0xFFFFFFFF),
    4: Color(0xFF04231A),
    5: Color(0xFF121212),
    6: Color(0xFF2A0F04),
  },
);

// ---------------------------------------------------------------------------
// Terminal (id 'terminal') -- green phosphor, six intensities.
//
// Real phosphor monitors were monochrome, which is what the previous Terminal
// got wrong by putting rainbow digits on black. One hue, six brightnesses.
// Like Slate, it stays legible without hue discrimination.
// ---------------------------------------------------------------------------

const _terminalDark = Palette(
  background: Color(0xFF000000),
  surface: Color(0xFF04120A),
  gridLine: Color(0xFF0F2E1A),
  boxLine: Color(0xFF1F7A3D),
  givenText: Color(0xFFD6FFE2),
  userText: Color(0xFF4EF07A),
  noteText: Color(0xFF4A8A5E),
  errorText: Color(0xFFFF5252),
  errorCell: Color(0xFF2E0D0D),
  selectedCell: Color(0xFF0E3D20),
  peerCell: Color(0xFF071F10),
  selectionRing: Color(0xFF4EF07A),
  peerScrim: Color(0x2033FF66),
  primary: Color(0xFF22C55E),
  hintCell: Color(0xFF125B2E),
  digitFills: {
    1: Color(0xFFC9FFD4),
    2: Color(0xFF8FFFA8),
    3: Color(0xFF4EF07A),
    4: Color(0xFF22C55E),
    5: Color(0xFF12833F),
    6: Color(0xFF0A5228),
  },
  digitTextColors: {
    1: Color(0xFF00160A),
    2: Color(0xFF00160A),
    3: Color(0xFF00160A),
    4: Color(0xFF00160A),
    5: Color(0xFFD6FFE2),
    6: Color(0xFFB9F5CC),
  },
);

const _terminalLight = Palette(
  background: Color(0xFFE8F2EA),
  surface: Color(0xFFF4FAF5),
  gridLine: Color(0xFFC6DCCB),
  boxLine: Color(0xFF1B5E20),
  givenText: Color(0xFF0B2410),
  userText: Color(0xFF1B6B39),
  noteText: Color(0xFF6A8571),
  errorText: Color(0xFFC62828),
  errorCell: Color(0xFFF5DBDB),
  selectedCell: Color(0xFFCFE6D6),
  peerCell: Color(0xFFDEEDE2),
  selectionRing: Color(0xFF1B6B39),
  peerScrim: Color(0x14000000),
  primary: Color(0xFF1B6B39),
  hintCell: Color(0xFFC4E3CD),
  digitFills: {
    1: Color(0xFFC6E9CE),
    2: Color(0xFF94D3A4),
    3: Color(0xFF59B673),
    4: Color(0xFF2A8850),
    5: Color(0xFF186036),
    6: Color(0xFF08361C),
  },
  digitTextColors: {
    1: Color(0xFF0B2410),
    2: Color(0xFF0B2410),
    3: Color(0xFF04240F),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFFFFF),
    6: Color(0xFFFFFFFF),
  },
);

// ---------------------------------------------------------------------------
// Ember (id 'apocalyptic') -- thermal ramp.
//
// Same charred mood as before, but the digits are a heat scale now instead of
// a rainbow: white-hot, flame, ember, rust, scorch, cold char.
// ---------------------------------------------------------------------------

const _emberDark = Palette(
  background: Color(0xFF120806),
  surface: Color(0xFF1E0F0A),
  gridLine: Color(0xFF35190F),
  boxLine: Color(0xFFFF5A1F),
  givenText: Color(0xFFFFE3D0),
  userText: Color(0xFFFFB020),
  noteText: Color(0xFF9A6B55),
  errorText: Color(0xFFFF5252),
  errorCell: Color(0xFF45120C),
  selectedCell: Color(0xFF3D1A0C),
  peerCell: Color(0xFF24100A),
  selectionRing: Color(0xFFFF6B18),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFFF6B18),
  hintCell: Color(0xFF4A2410),
  digitFills: {
    1: Color(0xFFFFE8A3),
    2: Color(0xFFFFB020),
    3: Color(0xFFFF6B18),
    4: Color(0xFFD93A0B),
    5: Color(0xFF8C2410),
    6: Color(0xFF4A231A),
  },
  digitTextColors: {
    1: Color(0xFF2B1A00),
    2: Color(0xFF2B1400),
    3: Color(0xFF2A0C00),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFD9C2),
    6: Color(0xFFE8B9A5),
  },
);

const _emberLight = Palette(
  background: Color(0xFFFAF0E6),
  surface: Color(0xFFFFF8F0),
  gridLine: Color(0xFFE8D5C4),
  boxLine: Color(0xFFC2410C),
  givenText: Color(0xFF33190C),
  userText: Color(0xFFC2410C),
  noteText: Color(0xFF8A6B58),
  errorText: Color(0xFFB91C1C),
  errorCell: Color(0xFFFBE0DA),
  selectedCell: Color(0xFFFCE0BF),
  peerCell: Color(0xFFF3E7DA),
  selectionRing: Color(0xFFC2410C),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFC2410C),
  hintCell: Color(0xFFFBD9B4),
  digitFills: {
    1: Color(0xFFFFD98A),
    2: Color(0xFFFFA23A),
    3: Color(0xFFF2691C),
    4: Color(0xFFC43B0E),
    5: Color(0xFF8A2A10),
    6: Color(0xFF4E2A1E),
  },
  digitTextColors: {
    1: Color(0xFF3A2400),
    2: Color(0xFF3A1C00),
    3: Color(0xFF2E0C00),
    4: Color(0xFFFFFFFF),
    5: Color(0xFFFFE2D2),
    6: Color(0xFFF2D5C6),
  },
);

// ---------------------------------------------------------------------------
// Bloom (id 'blossom') -- one floral gradient, petal to iris.
//
// The text color flips from ink to white partway down the ramp, which is a
// consequence of the gradient rather than an inconsistency: the pale end
// cannot carry white text and the deep end cannot carry ink.
// ---------------------------------------------------------------------------

const _bloomLight = Palette(
  background: Color(0xFFFFF7FA),
  surface: Color(0xFFFFFFFF),
  gridLine: Color(0xFFF2D9E2),
  boxLine: Color(0xFFA8437A),
  givenText: Color(0xFF3A1024),
  userText: Color(0xFFC2417F),
  noteText: Color(0xFF9B7A8A),
  errorText: Color(0xFFC2185B),
  errorCell: Color(0xFFFDE0E9),
  selectedCell: Color(0xFFFBDCE9),
  peerCell: Color(0xFFFCEFF4),
  selectionRing: Color(0xFFC2417F),
  peerScrim: Color(0x14000000),
  primary: Color(0xFFC2417F),
  hintCell: Color(0xFFF7D2E4),
  digitFills: {
    1: Color(0xFFFFD9E1),
    2: Color(0xFFF7A8BE),
    3: Color(0xFFE85A88),
    4: Color(0xFFB85CB0),
    5: Color(0xFF7B54B8),
    6: Color(0xFF463D8C),
  },
  digitTextColors: {
    1: Color(0xFF4A1526),
    2: Color(0xFF4A1526),
    3: Color(0xFF40101F),
    4: Color(0xFF2A0A28),
    5: Color(0xFFFFFFFF),
    6: Color(0xFFFFFFFF),
  },
);

const _bloomDark = Palette(
  background: Color(0xFF150C1A),
  surface: Color(0xFF221430),
  gridLine: Color(0xFF33204A),
  boxLine: Color(0xFFC77DD9),
  givenText: Color(0xFFFCE4F0),
  userText: Color(0xFFF58FB0),
  noteText: Color(0xFFA085B0),
  errorText: Color(0xFFFF6B8A),
  errorCell: Color(0xFF3D1020),
  selectedCell: Color(0xFF35204A),
  peerCell: Color(0xFF1E1228),
  selectionRing: Color(0xFFE05A8C),
  peerScrim: Color(0x1FFFFFFF),
  primary: Color(0xFFE05A8C),
  hintCell: Color(0xFF3D2452),
  digitFills: {
    1: Color(0xFFFFD3E0),
    2: Color(0xFFF58FB0),
    3: Color(0xFFE05A8C),
    4: Color(0xFFB357AE),
    5: Color(0xFF7E56C8),
    6: Color(0xFF52409C),
  },
  digitTextColors: {
    1: Color(0xFF3B0E22),
    2: Color(0xFF3B0E22),
    3: Color(0xFF2A0716),
    4: Color(0xFF24082A),
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

  // Ids for these three predate their redesigns ('modern', 'postmodern',
  // 'apocalyptic') and are what existing installs have saved in Hive, so the
  // ids stay put while the look and display name move on. Anyone on a saved
  // scheme sees a different board after upgrading -- that is the intended
  // trade, and it beats silently resetting their choice to the default.
  static const slate = PaletteScheme(
    id: 'modern',
    name: 'Slate',
    description: 'Monochrome — digits read by weight',
    light: _slateLight,
    dark: _slateDark,
  );

  static const bauhaus = PaletteScheme(
    id: 'postmodern',
    name: 'Bauhaus',
    description: 'Primary shapes on bone paper',
    light: _bauhausLight,
    dark: _bauhausDark,
  );

  static const terminal = PaletteScheme(
    id: 'terminal',
    name: 'Terminal',
    description: 'Green phosphor, six intensities',
    light: _terminalLight,
    dark: _terminalDark,
  );

  static const ember = PaletteScheme(
    id: 'apocalyptic',
    name: 'Ember',
    description: 'Thermal ramp, white-hot to char',
    light: _emberLight,
    dark: _emberDark,
  );

  static const bloom = PaletteScheme(
    id: 'blossom',
    name: 'Bloom',
    description: 'One floral gradient, petal to iris',
    light: _bloomLight,
    dark: _bloomDark,
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
    slate,
    bauhaus,
    terminal,
    ember,
    bloom,
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
