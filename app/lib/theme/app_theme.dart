import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Font family bundled for Traditional Chinese text (LXGW WenKai Mono TC).
///
/// Used as a `fontFamilyFallback` so CJK glyphs render in this kai-style
/// monospace font while Latin text keeps the default font.
const List<String> chineseFontFallback = ['LXGWWenKaiMonoTC'];

/// The light [ThemeData] for the app.
ThemeData buildLightTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      fontFamilyFallback: chineseFontFallback,
    );

/// The dark [ThemeData] for the app.
ThemeData buildDarkTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF673AB7),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamilyFallback: chineseFontFallback,
    );

/// The forui theme for the mobile widgets (bottom navigation, etc.), with the
/// Chinese font as a fallback.
FThemeData buildForuiTheme(Brightness brightness) {
  final colors =
      brightness == Brightness.dark ? FColors.neutralDark : FColors.neutralLight;

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
