import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Font family bundled for Traditional Chinese text (LXGW WenKai Mono TC).
///
/// Used as a `fontFamilyFallback` so CJK glyphs render in this kai-style
/// monospace font while Latin text keeps the default font.
const List<String> chineseFontFallback = ['LXGWWenKaiMonoTC'];

/// Ancient gold used for text in the dark theme.
const Color ancientGold = Color(0xFFC8A44D);

/// The light [ThemeData] for the app.
ThemeData buildLightTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      fontFamilyFallback: chineseFontFallback,
    );

/// The dark [ThemeData] for the app, with ancient-gold text.
ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF673AB7),
    brightness: Brightness.dark,
  ).copyWith(
    onSurface: ancientGold,
    onSurfaceVariant: ancientGold,
  );

  final theme = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamilyFallback: chineseFontFallback,
  );

  return theme.copyWith(
    textTheme: theme.textTheme.apply(
      bodyColor: ancientGold,
      displayColor: ancientGold,
    ),
  );
}

/// The forui theme for the mobile widgets (bottom navigation, etc.), with the
/// Chinese font as a fallback and ancient-gold text in dark mode.
FThemeData buildForuiTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark
      ? FColors.neutralDark.copyWith(foreground: ancientGold)
      : FColors.neutralLight;

  return FThemeData(
    touch: true,
    colors: colors,
    typography: FTypography(
      display: FTypeface.inherit(
        colors: colors,
        touch: true,
        fontFamilyFallback: chineseFontFallback,
      ),
      body: FTypeface.inherit(
        colors: colors,
        touch: true,
        fontFamilyFallback: chineseFontFallback,
      ),
    ),
  );
}
