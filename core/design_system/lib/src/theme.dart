/// core/design_system/lib/src/theme.dart
///
/// Builds the light and dark [ThemeData] entirely from tokens. Screens use
/// `Theme.of(context)` plus the [VnTheme] extension; they never import raw
/// token colors directly for component styling.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

/// ThemeExtension exposing VocabNote-specific slots that ColorScheme lacks
/// (favorite star, muted text, input surface, success).
@immutable
class VnTheme extends ThemeExtension<VnTheme> {
  const VnTheme({required this.tokens});

  final VnColorTokens tokens;

  @override
  VnTheme copyWith({VnColorTokens? tokens}) =>
      VnTheme(tokens: tokens ?? this.tokens);

  @override
  VnTheme lerp(ThemeExtension<VnTheme>? other, double t) {
    if (other is! VnTheme) return this;
    // Real per-slot interpolation: theme transitions cross-fade instead of
    // snapping at the midpoint (the old `t < 0.5 ? this : other`).
    return VnTheme(tokens: VnColorTokens.lerp(tokens, other.tokens, t));
  }

  static VnTheme of(BuildContext context) =>
      Theme.of(context).extension<VnTheme>()!;
}

abstract final class VnThemeFactory {
  static ThemeData light() => _build(VnColorTokens.light, Brightness.light);

  static ThemeData dark() => _build(VnColorTokens.dark, Brightness.dark);

  /// High-contrast builds: same layout and typography, stronger border and
  /// text colors. Only used when the OS requests high contrast.
  static ThemeData lightHighContrast() =>
      _build(VnColorTokens.lightHighContrast, Brightness.light);

  static ThemeData darkHighContrast() =>
      _build(VnColorTokens.darkHighContrast, Brightness.dark);

  static TextTheme _textTheme(VnColorTokens c) {
    TextStyle style(double size, FontWeight weight, Color color,
            {double? height}) =>
        TextStyle(
          fontFamily: VnTypographyTokens.uiFamily,
          fontFamilyFallback: VnTypographyTokens.fallbackFamilies,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height ?? 1.4,
        );

    return TextTheme(
      displaySmall:
          style(VnTypeScale.displaySize, VnTypeScale.bold, c.textPrimary),
      headlineSmall:
          style(VnTypeScale.headlineSize, VnTypeScale.semiBold, c.textPrimary),
      titleLarge:
          style(VnTypeScale.titleSize, VnTypeScale.semiBold, c.textPrimary),
      titleMedium:
          style(VnTypeScale.bodySize, VnTypeScale.semiBold, c.textPrimary),
      bodyLarge: style(VnTypeScale.bodySize, VnTypeScale.regular, c.textPrimary),
      bodyMedium:
          style(VnTypeScale.bodySize, VnTypeScale.regular, c.textSecondary),
      bodySmall:
          style(VnTypeScale.bodySmallSize, VnTypeScale.regular, c.textMuted),
      labelLarge:
          style(VnTypeScale.bodySmallSize, VnTypeScale.medium, c.textPrimary),
      labelMedium:
          style(VnTypeScale.labelSize, VnTypeScale.medium, c.textSecondary),
      labelSmall:
          style(VnTypeScale.labelSize, VnTypeScale.medium, c.textMuted),
    );
  }

  static ThemeData _build(VnColorTokens c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentHover,
      onPrimaryContainer: c.onAccent,
      secondary: c.textSecondary,
      onSecondary: c.surface,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceRaised,
      surfaceContainerLow: c.background,
      outline: c.border,
      outlineVariant: c.border,
      shadow: const Color(0x33000000),
      scrim: const Color(0x66000000),
      inverseSurface: c.textPrimary,
      onInverseSurface: c.surface,
      inversePrimary: c.accentHover,
      surfaceTint: Colors.transparent,
      onSurfaceVariant: c.textSecondary,
    );

    final textTheme = _textTheme(c);
    final radiusMd = BorderRadius.circular(VnRadius.md);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[VnTheme(tokens: c)],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VnSpacing.x4,
          vertical: VnSpacing.x3,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: c.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(VnA11y.minTargetSize, VnA11y.minTargetSize),
          padding: const EdgeInsets.symmetric(
            horizontal: VnSpacing.x5,
            vertical: VnSpacing.x3,
          ),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(VnA11y.minTargetSize, VnA11y.minTargetSize),
          side: BorderSide(color: c.border),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(VnA11y.minTargetSize, VnA11y.minTargetSize),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(VnA11y.minTargetSize, VnA11y.minTargetSize),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        iconColor: c.textSecondary,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accent.withValues(alpha: 0.16),
        selectedIconTheme: IconThemeData(color: c.accent),
        unselectedIconTheme: IconThemeData(color: c.textMuted),
        selectedLabelTextStyle:
            textTheme.labelMedium?.copyWith(color: c.accent),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accent.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textMuted,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: c.surface),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceInput,
        side: BorderSide(color: c.border),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VnRadius.pill),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      // Anchored menus (VnSelect / VnOverflowMenuButton) share the raised
      // surface + border look of the app's other floating surfaces.
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(8),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: radiusMd,
              side: BorderSide(color: c.border),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: VnSpacing.x1),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: VnSpacing.x4),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.textMuted
                : c.textPrimary,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
                ? c.hover
                : null,
          ),
        ),
      ),
      // Safety net so any remaining PopupMenuButton matches the same look.
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: c.border),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      focusColor: c.accent.withValues(alpha: VnOpacity.focus),
      hoverColor: c.hover.withValues(alpha: VnOpacity.hoverStrong),
    );
  }
}
