import 'package:flutter/material.dart';

/// Default orange and navy. Screens read [LiftBigPalette] from the theme.
abstract final class LiftBigColors {
  static const background = Color(0xFF0A0F1E);
  static const card = Color(0xFF1C2738);
  static const cardInner = Color(0xFF141E30);
  static const border = Color(0xFF3A4E72);
  static const primary = Color(0xFFF4501E);
  static const foreground = Color(0xFFF0F4FF);
  static const muted = Color(0xFF8A97B0);
  static const success = Color(0xFF4ADE80);
}

const String defaultLiftBigThemeId = 'default';

/// Backdrop ids. [none] is a flat color. The others are Pro patterns.
abstract final class LiftBigBackdrop {
  static const none = 'none';
  static const plateStack = 'plate-stack';
  static const chalkGrid = 'chalk-grid';
  static const hazardStripe = 'hazard-stripe';
  static const signalSweep = 'signal-sweep';
  static const emberDrift = 'ember-drift';
  static const barPath = 'bar-path';
  static const rackGlow = 'rack-glow';
  static const knurl = 'knurl';

  /// Slow motion. Static patterns stay off this list so they paint once.
  static bool animates(String id) {
    return id == signalSweep ||
        id == emberDrift ||
        id == barPath ||
        id == rackGlow;
  }
}

/// Named Vue presets from `main.css`, plus Pro backdrops.
/// Custom editing stays out of this pass.
class LiftBigPalette extends ThemeExtension<LiftBigPalette> {
  const LiftBigPalette({
    required this.id,
    required this.label,
    required this.background,
    required this.card,
    required this.cardInner,
    required this.border,
    required this.primary,
    required this.foreground,
    required this.muted,
    required this.success,
    required this.blue,
    Color? canvas,
    this.proOnly = false,
    this.backdrop = LiftBigBackdrop.none,
  }) : canvas = canvas ?? background;

  final String id;
  final String label;

  /// Page fill. Pro themes leave this transparent so the backdrop painted
  /// behind the app can show through scaffolds that use this color.
  final Color background;

  /// Solid color under a Pro backdrop. Free themes keep this equal to
  /// [background].
  final Color canvas;
  final Color card;
  final Color cardInner;
  final Color border;
  final Color primary;
  final Color foreground;
  final Color muted;
  final Color success;
  final Color blue;
  final bool proOnly;
  final String backdrop;

  /// Near-black on a light primary, white on a dark one.
  Color get onPrimary {
    final light =
        ThemeData.estimateBrightnessForColor(primary) == Brightness.light;
    return light ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  }

  static LiftBigPalette of(BuildContext context) {
    return Theme.of(context).extension<LiftBigPalette>() ??
        liftBigThemePresets.first;
  }

  @override
  LiftBigPalette copyWith({
    String? id,
    String? label,
    Color? background,
    Color? canvas,
    Color? card,
    Color? cardInner,
    Color? border,
    Color? primary,
    Color? foreground,
    Color? muted,
    Color? success,
    Color? blue,
    bool? proOnly,
    String? backdrop,
  }) {
    return LiftBigPalette(
      id: id ?? this.id,
      label: label ?? this.label,
      background: background ?? this.background,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardInner: cardInner ?? this.cardInner,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      success: success ?? this.success,
      blue: blue ?? this.blue,
      proOnly: proOnly ?? this.proOnly,
      backdrop: backdrop ?? this.backdrop,
    );
  }

  @override
  LiftBigPalette lerp(ThemeExtension<LiftBigPalette>? other, double t) {
    if (other is! LiftBigPalette) return this;
    return LiftBigPalette(
      id: t < 0.5 ? id : other.id,
      label: t < 0.5 ? label : other.label,
      background: Color.lerp(background, other.background, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardInner: Color.lerp(cardInner, other.cardInner, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      success: Color.lerp(success, other.success, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      proOnly: t < 0.5 ? proOnly : other.proOnly,
      backdrop: t < 0.5 ? backdrop : other.backdrop,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LiftBigPalette &&
        other.id == id &&
        other.background == background &&
        other.canvas == canvas &&
        other.card == card &&
        other.cardInner == cardInner &&
        other.border == border &&
        other.primary == primary &&
        other.foreground == foreground &&
        other.muted == muted &&
        other.success == success &&
        other.blue == blue &&
        other.proOnly == proOnly &&
        other.backdrop == backdrop;
  }

  @override
  int get hashCode => Object.hash(
    id,
    background,
    canvas,
    card,
    cardInner,
    border,
    primary,
    foreground,
    muted,
    success,
    blue,
    proOnly,
    backdrop,
  );
}

extension LiftBigThemeContext on BuildContext {
  LiftBigPalette get liftBig => LiftBigPalette.of(this);
}

/// Saved id, unknown values, and blank storage all resolve to orange/navy.
/// A Pro id resolves to that same default when [proActive] is false.
LiftBigPalette liftBigPaletteById(String? id, {bool proActive = true}) {
  final key = id?.trim() ?? '';
  for (final palette in liftBigThemePresets) {
    if (palette.id != key) continue;
    if (palette.proOnly && !proActive) return liftBigThemePresets.first;
    return palette;
  }
  return liftBigThemePresets.first;
}

class LiftBigThemeController extends ChangeNotifier {
  String id = defaultLiftBigThemeId;
  bool proActive = false;

  /// Pro ids stay stored. The painted palette falls back while Pro is off.
  LiftBigPalette get palette => liftBigPaletteById(id, proActive: proActive);

  void applyStored(String? raw, {bool proActive = false}) {
    final key = raw?.trim() ?? '';
    var next = defaultLiftBigThemeId;
    for (final palette in liftBigThemePresets) {
      if (palette.id == key) {
        next = palette.id;
        break;
      }
    }
    final changed = next != id || proActive != this.proActive;
    id = next;
    this.proActive = proActive;
    if (changed) notifyListeners();
  }

  void setProActive(bool active) {
    if (active == proActive) return;
    proActive = active;
    notifyListeners();
  }

  void select(String raw) {
    final next = liftBigPaletteById(raw);
    if (next.proOnly && !proActive) return;
    if (next.id == id) return;
    id = next.id;
    notifyListeners();
  }
}

const List<LiftBigPalette> liftBigThemePresets = [
  LiftBigPalette(
    id: 'default',
    label: 'LiftBig (orange)',
    background: LiftBigColors.background,
    card: LiftBigColors.card,
    cardInner: LiftBigColors.cardInner,
    border: LiftBigColors.border,
    primary: LiftBigColors.primary,
    foreground: LiftBigColors.foreground,
    muted: LiftBigColors.muted,
    success: LiftBigColors.success,
    blue: Color(0xFF1D4ED8),
  ),
  LiftBigPalette(
    id: 'retrowave',
    label: 'Retrowave',
    background: Color(0xFF0A0418),
    card: Color(0xFF281050),
    cardInner: Color(0xFF1C0838),
    border: Color(0xFFFF2A92),
    primary: Color(0xFFFF6EC7),
    blue: Color(0xFF00D4FF),
    foreground: Color(0xFFFFF0F9),
    muted: Color(0xFFD880B4),
    success: Color(0xFFBBF7D0),
  ),
  LiftBigPalette(
    id: 'forest',
    label: 'Forest',
    background: Color(0xFF021408),
    card: Color(0xFF1A3D28),
    cardInner: Color(0xFF122818),
    border: Color(0xFF22C55E),
    primary: Color(0xFF4ADE80),
    blue: Color(0xFFFBBF24),
    foreground: Color(0xFFF0FDF4),
    muted: Color(0xFF7DB095),
    success: Color(0xFF5EEAD4),
  ),
  LiftBigPalette(
    id: 'violet',
    label: 'Violet',
    background: Color(0xFF080312),
    card: Color(0xFF241045),
    cardInner: Color(0xFF180830),
    border: Color(0xFF7C3AED),
    primary: Color(0xFFC084FC),
    blue: Color(0xFFF472B6),
    foreground: Color(0xFFF5F3FF),
    muted: Color(0xFF9B85C8),
    success: Color(0xFFA5F3FC),
  ),
  LiftBigPalette(
    id: 'sunset',
    label: 'Sunset',
    background: Color(0xFF180508),
    card: Color(0xFF381018),
    cardInner: Color(0xFF280810),
    border: Color(0xFFF43F5E),
    primary: Color(0xFFFF6B8A),
    blue: Color(0xFFFB923C),
    foreground: Color(0xFFFFF1F2),
    muted: Color(0xFFD4748A),
    success: Color(0xFFFEF9C3),
  ),
  LiftBigPalette(
    id: 'loud',
    label: 'Loud',
    background: Color(0xFF120018),
    card: Color(0xFF240030),
    cardInner: Color(0xFF1A0024),
    border: Color(0xFFFF00CC),
    primary: Color(0xFFFFFB00),
    blue: Color(0xFF00F5FF),
    foreground: Color(0xFFFFFFFF),
    muted: Color(0xFFFF6EC7),
    success: Color(0xFFCCFF00),
  ),
  LiftBigPalette(
    id: 'cyberpunk',
    label: 'Cyberpunk',
    background: Color(0xFF050810),
    card: Color(0xFF0C1220),
    cardInner: Color(0xFF080C18),
    border: Color(0xFF00F0FF),
    primary: Color(0xFFFF2A6D),
    blue: Color(0xFF05D9E8),
    foreground: Color(0xFFE8F4FF),
    muted: Color(0xFF6B8FB3),
    success: Color(0xFFB4FFC9),
  ),
  LiftBigPalette(
    id: 'iron',
    label: 'Iron & Steel',
    background: Color(0xFF0F1115),
    card: Color(0xFF242830),
    cardInner: Color(0xFF1A1E26),
    border: Color(0xFF5C6578),
    primary: Color(0xFFF97316),
    blue: Color(0xFF64748B),
    foreground: Color(0xFFF1F5F9),
    muted: Color(0xFF8B95A8),
    success: Color(0xFF86EFAC),
  ),
  LiftBigPalette(
    id: 'aurora',
    label: 'Aurora',
    background: Color(0xFF041210),
    card: Color(0xFF0F3028),
    cardInner: Color(0xFF0A221C),
    border: Color(0xFF1F4D45),
    primary: Color(0xFF5EEAD4),
    blue: Color(0xFFA78BFA),
    foreground: Color(0xFFECFEFF),
    muted: Color(0xFF6B9E94),
    success: Color(0xFFBBF7D0),
  ),
  LiftBigPalette(
    id: 'bubblegum',
    label: 'Bubblegum',
    background: Color(0xFF18041C),
    card: Color(0xFF502060),
    cardInner: Color(0xFF381448),
    border: Color(0xFFF472B6),
    primary: Color(0xFFFF6EB4),
    blue: Color(0xFF67E8F9),
    foreground: Color(0xFFFDF2F8),
    muted: Color(0xFFE08EC4),
    success: Color(0xFFFEF9C3),
  ),
  LiftBigPalette(
    id: 'midnight',
    label: 'Midnight sky',
    background: Color(0xFF020510),
    card: Color(0xFF121E42),
    cardInner: Color(0xFF0C1430),
    border: Color(0xFF3B82F6),
    primary: Color(0xFFA5C8FF),
    blue: Color(0xFF60A5FA),
    foreground: Color(0xFFEFF6FF),
    muted: Color(0xFF7DA0D8),
    success: Color(0xFFA7F3D0),
  ),
  LiftBigPalette(
    id: 'sandstorm',
    label: 'Sandstorm',
    background: Color(0xFF140E06),
    card: Color(0xFF3D2A14),
    cardInner: Color(0xFF2A1C0C),
    border: Color(0xFFF59E0B),
    primary: Color(0xFFFBBF24),
    blue: Color(0xFFF97316),
    foreground: Color(0xFFFFFBEB),
    muted: Color(0xFFD4A95E),
    success: Color(0xFFECFCCB),
  ),
  LiftBigPalette(
    id: 'cherrylime',
    label: 'Cherry lime',
    background: Color(0xFF120810),
    card: Color(0xFF381018),
    cardInner: Color(0xFF1A2808),
    border: Color(0xFFBE185D),
    primary: Color(0xFFF43F5E),
    blue: Color(0xFFA3E635),
    foreground: Color(0xFFFFF1F2),
    muted: Color(0xFFC49AA8),
    success: Color(0xFFECFCCB),
  ),
  LiftBigPalette(
    id: 'terminal',
    label: 'Terminal',
    background: Color(0xFF010402),
    card: Color(0xFF0A200A),
    cardInner: Color(0xFF061806),
    border: Color(0xFF22C55E),
    primary: Color(0xFF4ADE80),
    blue: Color(0xFFFBBF24),
    foreground: Color(0xFFDCFCE7),
    muted: Color(0xFF5CB87A),
    success: Color(0xFFA5F3FC),
  ),
  LiftBigPalette(
    id: 'disco',
    label: 'Disco',
    background: Color(0xFF100818),
    card: Color(0xFF281845),
    cardInner: Color(0xFF1C1030),
    border: Color(0xFFC084FC),
    primary: Color(0xFFFDE047),
    blue: Color(0xFFE879F9),
    foreground: Color(0xFFFEFCE8),
    muted: Color(0xFFD8B4FE),
    success: Color(0xFFA7F3D0),
  ),
  LiftBigPalette(
    id: 'ocean',
    label: 'Ocean depths',
    background: Color(0xFF020C18),
    card: Color(0xFF0A2848),
    cardInner: Color(0xFF061830),
    border: Color(0xFF06B6D4),
    primary: Color(0xFF22D3EE),
    blue: Color(0xFF6366F1),
    foreground: Color(0xFFECFEFF),
    muted: Color(0xFF5EC4D8),
    success: Color(0xFFFBCFE8),
  ),
  LiftBigPalette(
    id: 'voltage',
    label: 'Voltage Surge',
    background: Color(0xFF05070F),
    card: Color(0xFF181830),
    cardInner: Color(0xFF101020),
    border: Color(0xFFFACC15),
    primary: Color(0xFFFDE047),
    blue: Color(0xFF22D3EE),
    foreground: Color(0xFFFEFCE8),
    muted: Color(0xFFC8B95A),
    success: Color(0xFFBBF7D0),
  ),
  LiftBigPalette(
    id: 'dragonfruit',
    label: 'Dragonfruit Punch',
    background: Color(0xFF120012),
    card: Color(0xFF381040),
    cardInner: Color(0xFF280830),
    border: Color(0xFFFB7185),
    primary: Color(0xFFFF4FD8),
    blue: Color(0xFFA3E635),
    foreground: Color(0xFFFFF1FB),
    muted: Color(0xFFE6A7D3),
    success: Color(0xFFECFCCB),
  ),
  LiftBigPalette(
    id: 'glacier',
    label: 'Glacier Glow',
    background: Color(0xFF031018),
    card: Color(0xFF0C2840),
    cardInner: Color(0xFF081C30),
    border: Color(0xFF67E8F9),
    primary: Color(0xFFA5F3FC),
    blue: Color(0xFFC4B5FD),
    foreground: Color(0xFFECFEFF),
    muted: Color(0xFF8BD3DF),
    success: Color(0xFFBAE6FD),
  ),
  LiftBigPalette(
    id: 'lavaflow',
    label: 'Lava Flow',
    background: Color(0xFF120402),
    card: Color(0xFF401008),
    cardInner: Color(0xFF280804),
    border: Color(0xFFF97316),
    primary: Color(0xFFFB923C),
    blue: Color(0xFFEF4444),
    foreground: Color(0xFFFFF7ED),
    muted: Color(0xFFE7A37D),
    success: Color(0xFFFEF9C3),
  ),
  LiftBigPalette(
    id: 'nebula',
    label: 'Cosmic Nebula',
    background: Color(0xFF060318),
    card: Color(0xFF1A1040),
    cardInner: Color(0xFF120830),
    border: Color(0xFF8B5CF6),
    primary: Color(0xFFC084FC),
    blue: Color(0xFF22D3EE),
    foreground: Color(0xFFFAF5FF),
    muted: Color(0xFFBAA7E8),
    success: Color(0xFFA7F3D0),
  ),
  LiftBigPalette(
    id: 'toxic',
    label: 'Toxic Limeade',
    background: Color(0xFF041006),
    card: Color(0xFF1A3810),
    cardInner: Color(0xFF102808),
    border: Color(0xFFA3E635),
    primary: Color(0xFFD9F99D),
    blue: Color(0xFF14B8A6),
    foreground: Color(0xFFF7FEE7),
    muted: Color(0xFFA9C96D),
    success: Color(0xFFECFCCB),
  ),
  LiftBigPalette(
    id: 'sapphire',
    label: 'Sapphire Storm',
    background: Color(0xFF020818),
    card: Color(0xFF0C2048),
    cardInner: Color(0xFF081838),
    border: Color(0xFF2563EB),
    primary: Color(0xFF60A5FA),
    blue: Color(0xFF22D3EE),
    foreground: Color(0xFFEFF6FF),
    muted: Color(0xFF8FB6EF),
    success: Color(0xFFDDD6FE),
  ),
  LiftBigPalette(
    id: 'mango',
    label: 'Mango Tango',
    background: Color(0xFF140802),
    card: Color(0xFF402010),
    cardInner: Color(0xFF301408),
    border: Color(0xFFFB923C),
    primary: Color(0xFFFBBF24),
    blue: Color(0xFFFB7185),
    foreground: Color(0xFFFFF7ED),
    muted: Color(0xFFE8B673),
    success: Color(0xFFECFCCB),
  ),
  LiftBigPalette(
    id: 'prism',
    label: 'Prism Pop',
    background: Color(0xFF060610),
    card: Color(0xFF181830),
    cardInner: Color(0xFF101020),
    border: Color(0xFFF0ABFC),
    primary: Color(0xFFF9A8D4),
    blue: Color(0xFF67E8F9),
    foreground: Color(0xFFFFFFFF),
    muted: Color(0xFFCFC7FF),
    success: Color(0xFFDCFCE7),
  ),
  LiftBigPalette(
    id: 'mintchip',
    label: 'Mint Chip',
    background: Color(0xFF031410),
    card: Color(0xFF0C3828),
    cardInner: Color(0xFF082818),
    border: Color(0xFF6EE7B7),
    primary: Color(0xFF99F6E4),
    blue: Color(0xFF92400E),
    foreground: Color(0xFFF0FDFA),
    muted: Color(0xFF8BD9C0),
    success: Color(0xFFFDE68A),
  ),
  LiftBigPalette(
    id: 'tidal',
    label: 'Tidal Wave',
    background: Color(0xFF021018),
    card: Color(0xFF0A3040),
    cardInner: Color(0xFF062830),
    border: Color(0xFF2DD4BF),
    primary: Color(0xFF5EEAD4),
    blue: Color(0xFFF472B6),
    foreground: Color(0xFFECFEFF),
    muted: Color(0xFF85D6CE),
    success: Color(0xFF7DD3FC),
  ),
  LiftBigPalette(
    id: 'cottoncandy',
    label: 'Cotton Candy Sky',
    background: Color(0xFF100418),
    card: Color(0xFF381848),
    cardInner: Color(0xFF281030),
    border: Color(0xFFF9A8D4),
    primary: Color(0xFFF0ABFC),
    blue: Color(0xFF67E8F9),
    foreground: Color(0xFFFDF4FF),
    muted: Color(0xFFE8B9DD),
    success: Color(0xFFFEF9C3),
  ),
  LiftBigPalette(
    id: 'bloodmoon',
    label: 'Blood Moon',
    background: Color(0xFF0C0204),
    card: Color(0xFF381018),
    cardInner: Color(0xFF28080C),
    border: Color(0xFFDC2626),
    primary: Color(0xFFEF4444),
    blue: Color(0xFFF97316),
    foreground: Color(0xFFFEF2F2),
    muted: Color(0xFFD4606A),
    success: Color(0xFFFEF9C3),
  ),
  LiftBigPalette(
    id: 'titanium',
    label: 'Titanium',
    background: Color(0xFF08090E),
    card: Color(0xFF1C202C),
    cardInner: Color(0xFF141820),
    border: Color(0xFF7D8CA3),
    primary: Color(0xFF94A3B8),
    blue: Color(0xFFF97316),
    foreground: Color(0xFFF1F5F9),
    muted: Color(0xFF8494A8),
    success: Color(0xFFA5F3FC),
  ),
  LiftBigPalette(
    id: 'plate-stack',
    label: 'Plate Stack',
    background: Colors.transparent,
    canvas: Color(0xFF0E1116),
    card: Color(0xFF1E2633),
    cardInner: Color(0xFF161C28),
    border: Color(0xFF4A566C),
    primary: Color(0xFFE25A2A),
    blue: Color(0xFF8B9BB0),
    foreground: Color(0xFFF3F5F8),
    muted: Color(0xFFA8B4C8),
    success: Color(0xFF4ADE80),
    proOnly: true,
    backdrop: LiftBigBackdrop.plateStack,
  ),
  LiftBigPalette(
    id: 'chalk-grid',
    label: 'Chalk Grid',
    background: Colors.transparent,
    canvas: Color(0xFF161816),
    card: Color(0xFF262A26),
    cardInner: Color(0xFF1E221E),
    border: Color(0xFF5A6156),
    primary: Color(0xFFE6E1D2),
    blue: Color(0xFF9AA58E),
    foreground: Color(0xFFF6F3EA),
    muted: Color(0xFFC8C4B6),
    success: Color(0xFFB6E2A1),
    proOnly: true,
    backdrop: LiftBigBackdrop.chalkGrid,
  ),
  LiftBigPalette(
    id: 'hazard-stripe',
    label: 'Hazard Stripe',
    background: Colors.transparent,
    canvas: Color(0xFF12110C),
    card: Color(0xFF2A2618),
    cardInner: Color(0xFF1E1C12),
    border: Color(0xFF8A7018),
    primary: Color(0xFFF5C518),
    blue: Color(0xFFF97316),
    foreground: Color(0xFFFFF8E4),
    muted: Color(0xFFE0D2A0),
    success: Color(0xFFD6F5A3),
    proOnly: true,
    backdrop: LiftBigBackdrop.hazardStripe,
  ),
  LiftBigPalette(
    id: 'signal-sweep',
    label: 'Signal Sweep',
    background: Colors.transparent,
    canvas: Color(0xFF061410),
    card: Color(0xFF123028),
    cardInner: Color(0xFF0C241E),
    border: Color(0xFF1F6B52),
    primary: Color(0xFF3DDC97),
    blue: Color(0xFF5EEAD4),
    foreground: Color(0xFFE9FFF6),
    muted: Color(0xFF9AD4C0),
    success: Color(0xFFBBF7D0),
    proOnly: true,
    backdrop: LiftBigBackdrop.signalSweep,
  ),
  LiftBigPalette(
    id: 'ember-drift',
    label: 'Ember Drift',
    background: Colors.transparent,
    canvas: Color(0xFF160806),
    card: Color(0xFF3A1810),
    cardInner: Color(0xFF2A100C),
    border: Color(0xFF9A3412),
    primary: Color(0xFFFB923C),
    blue: Color(0xFFF43F5E),
    foreground: Color(0xFFFFF7ED),
    muted: Color(0xFFF0C0A0),
    success: Color(0xFFFDE68A),
    proOnly: true,
    backdrop: LiftBigBackdrop.emberDrift,
  ),
  LiftBigPalette(
    id: 'bar-path',
    label: 'Bar Path',
    background: Colors.transparent,
    canvas: Color(0xFF0C1018),
    card: Color(0xFF1A2433),
    cardInner: Color(0xFF121A28),
    border: Color(0xFF3D5270),
    primary: Color(0xFF7DD3FC),
    blue: Color(0xFFA5B4FC),
    foreground: Color(0xFFF0F9FF),
    muted: Color(0xFFB6C8DC),
    success: Color(0xFF86EFAC),
    proOnly: true,
    backdrop: LiftBigBackdrop.barPath,
  ),
  LiftBigPalette(
    id: 'rack-glow',
    label: 'Rack Glow',
    background: Colors.transparent,
    canvas: Color(0xFF140E0A),
    card: Color(0xFF2E2218),
    cardInner: Color(0xFF22180F),
    border: Color(0xFF8A6240),
    primary: Color(0xFFFBBF24),
    blue: Color(0xFFFB7185),
    foreground: Color(0xFFFFF7ED),
    muted: Color(0xFFE6C9A4),
    success: Color(0xFFD9F99D),
    proOnly: true,
    backdrop: LiftBigBackdrop.rackGlow,
  ),
  LiftBigPalette(
    id: 'knurl',
    label: 'Knurl',
    background: Colors.transparent,
    canvas: Color(0xFF121416),
    card: Color(0xFF262A2E),
    cardInner: Color(0xFF1C2024),
    border: Color(0xFF5E6872),
    primary: Color(0xFFE7EEF5),
    blue: Color(0xFF94A3B8),
    foreground: Color(0xFFF8FAFC),
    muted: Color(0xFFC9D2DC),
    success: Color(0xFFA7F3D0),
    proOnly: true,
    backdrop: LiftBigBackdrop.knurl,
  ),
];

/// A short notice at the top of the screen, clear of the bottom bar.
void showLiftBigNotice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  final media = MediaQuery.of(context);
  final top = media.padding.top + 8;
  final side = ((media.size.width - 280) / 2).clamp(20.0, 80.0);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.up,
      margin: EdgeInsets.fromLTRB(side, 0, side, media.size.height - top - 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      duration: const Duration(seconds: 3),
    ),
  );
}

ThemeData buildLiftBigTheme([LiftBigPalette? palette]) {
  final colors = palette ?? liftBigThemePresets.first;
  final base = colors.canvas;
  final patterned = colors.backdrop != LiftBigBackdrop.none;
  final shape = RoundedRectangleBorder(
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    side: BorderSide(color: colors.border),
  );
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: patterned ? Colors.transparent : base,
    extensions: [colors],
    colorScheme: ColorScheme.dark(
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      surface: base,
      onSurface: colors.foreground,
      secondary: colors.primary,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: base,
      surfaceContainerLow: base,
      surfaceContainer: base,
      surfaceContainerHigh: base,
      surfaceContainerHighest: colors.card,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: patterned ? Colors.transparent : base,
      foregroundColor: colors.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(color: colors.card, shape: shape),
    dividerColor: colors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.cardInner,
      labelStyle: TextStyle(color: colors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.foreground,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentTextStyle: TextStyle(
        color: colors.foreground,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        side: BorderSide(color: colors.primary, width: 1.5),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: colors.primary, width: 1.5),
      ),
    ),
  );
}
