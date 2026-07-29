/// core/design_system/lib/src/tokens.dart
///
/// Raw design tokens. Nothing in here is a Flutter ThemeData; these are the
/// primitive values every theme, widget, and golden test derives from.
/// No component may use a literal color/spacing value: it must come from here.
library;

import 'dart:ui';

/// Spacing scale on a 4pt grid. Use these instead of literal EdgeInsets values.
abstract final class VnSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}

/// Corner radii.
abstract final class VnRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Elevation/opacity tokens.
abstract final class VnOpacity {
  static const double disabled = 0.38;
  static const double muted = 0.64;
  static const double hover = 0.08;

  /// Strong hover emphasis for filled hover surfaces (menu items, list
  /// rows). Kept as a named token so no call site hard-codes the value.
  static const double hoverStrong = 0.48;
  static const double focus = 0.12;
}

/// Minimum interactive target size (accessibility contract: >= 44x44 dp).
abstract final class VnA11y {
  static const double minTargetSize = 44;
}

/// Type scale tokens (sizes/weights only; families live in [VnTypographyTokens]).
abstract final class VnTypeScale {
  static const double displaySize = 32;
  static const double headlineSize = 24;
  static const double titleSize = 18;
  static const double bodySize = 15;
  static const double bodySmallSize = 13;
  static const double labelSize = 12;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}

/// Font families. The Bengali fallback is part of the product contract
/// (Bangla translations must always render correctly).
abstract final class VnTypographyTokens {
  static const String uiFamily = 'Inter';
  static const List<String> fallbackFamilies = <String>[
    'Noto Sans Bengali',
    'Noto Sans',
  ];
}

/// A resolved color scheme for one brightness. Both palettes carry the same
/// slots so components never branch on brightness themselves.
final class VnColorTokens {
  const VnColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceInput,
    required this.hover,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentHover,
    required this.onAccent,
    required this.favorite,
    required this.success,
    required this.danger,
    required this.onDanger,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceInput;
  final Color hover;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentHover;
  final Color onAccent;
  final Color favorite;
  final Color success;
  final Color danger;
  final Color onDanger;

  /// Copy with individual slots overridden. Tokens are colors only, so this
  /// can never affect layout.
  VnColorTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceInput,
    Color? hover,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentHover,
    Color? onAccent,
    Color? favorite,
    Color? success,
    Color? danger,
    Color? onDanger,
  }) =>
      VnColorTokens(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        surfaceInput: surfaceInput ?? this.surfaceInput,
        hover: hover ?? this.hover,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        accent: accent ?? this.accent,
        accentHover: accentHover ?? this.accentHover,
        onAccent: onAccent ?? this.onAccent,
        favorite: favorite ?? this.favorite,
        success: success ?? this.success,
        danger: danger ?? this.danger,
        onDanger: onDanger ?? this.onDanger,
      );

  /// Linear interpolation between two token sets. Used by [VnTheme.lerp] so
  /// theme transitions cross-fade smoothly instead of snapping at t = 0.5.
  static VnColorTokens lerp(VnColorTokens a, VnColorTokens b, double t) =>
      VnColorTokens(
        background: Color.lerp(a.background, b.background, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
        surfaceInput: Color.lerp(a.surfaceInput, b.surfaceInput, t)!,
        hover: Color.lerp(a.hover, b.hover, t)!,
        border: Color.lerp(a.border, b.border, t)!,
        textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
        textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
        textMuted: Color.lerp(a.textMuted, b.textMuted, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        accentHover: Color.lerp(a.accentHover, b.accentHover, t)!,
        onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
        favorite: Color.lerp(a.favorite, b.favorite, t)!,
        success: Color.lerp(a.success, b.success, t)!,
        danger: Color.lerp(a.danger, b.danger, t)!,
        onDanger: Color.lerp(a.onDanger, b.onDanger, t)!,
      );

  /// Dark palette: derived from the legacy desktop app's proven scheme
  /// (APP_BG #16171B, CARD_BG #21232A, ACCENT #1877F2, etc.), with contrast
  /// adjustments to meet WCAG 2.2 AA on all text slots.
  static const VnColorTokens dark = VnColorTokens(
    background: Color(0xFF16171B),
    surface: Color(0xFF1C1E24),
    surfaceRaised: Color(0xFF21232A),
    surfaceInput: Color(0xFF0D0E11),
    hover: Color(0xFF2D303B),
    border: Color(0xFF323642),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B9C4),
    textMuted: Color(0xFF8A91A0),
    accent: Color(0xFF3B8BFF),
    accentHover: Color(0xFF5C9EFF),
    onAccent: Color(0xFF06121F),
    favorite: Color(0xFFF59E0B),
    success: Color(0xFF2BC48A),
    danger: Color(0xFFF0544C),
    onDanger: Color(0xFFFFFFFF),
  );

  /// Light palette: same hue relationships, inverted value ramp.
  static const VnColorTokens light = VnColorTokens(
    background: Color(0xFFF7F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceInput: Color(0xFFEFF0F3),
    hover: Color(0xFFE9EBEF),
    border: Color(0xFFD9DCE3),
    textPrimary: Color(0xFF14161B),
    textSecondary: Color(0xFF4B5261),
    textMuted: Color(0xFF6E7688),
    accent: Color(0xFF1668DC),
    accentHover: Color(0xFF0F56BD),
    onAccent: Color(0xFFFFFFFF),
    favorite: Color(0xFFB45309),
    success: Color(0xFF0E8A5F),
    danger: Color(0xFFC93A32),
    onDanger: Color(0xFFFFFFFF),
  );

  /// High-contrast variants: identical layout, stronger border and
  /// secondary-text colors. Served only when the OS requests high contrast
  /// (MaterialApp.highContrastTheme / highContrastDarkTheme), so normal
  /// rendering is completely unchanged.
  static final VnColorTokens darkHighContrast = dark.copyWith(
    border: const Color(0xFF7A8296),
    textSecondary: const Color(0xFFD5DAE2),
    textMuted: const Color(0xFFB9BFCC),
  );

  static final VnColorTokens lightHighContrast = light.copyWith(
    border: const Color(0xFF6E7688),
    textSecondary: const Color(0xFF2A2F3A),
    textMuted: const Color(0xFF4B5261),
  );
}

/// Motion tokens.
abstract final class VnMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}
