import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/theme/app_theme.dart';

void main() {
  test('chinese font fallback is set on both themes', () {
    expect(chineseFontFallback, contains('LXGWWenKaiMonoTC'));

    final light = buildLightTheme();
    final dark = buildDarkTheme();

    expect(
      light.textTheme.bodyMedium?.fontFamilyFallback,
      contains('LXGWWenKaiMonoTC'),
    );
    expect(
      dark.textTheme.bodyMedium?.fontFamilyFallback,
      contains('LXGWWenKaiMonoTC'),
    );
  });

  test('dark theme is dark and light theme is light', () {
    expect(buildLightTheme().brightness, Brightness.light);
    expect(buildDarkTheme().brightness, Brightness.dark);
  });

  test('dark theme text is ancient gold', () {
    final dark = buildDarkTheme();
    expect(dark.colorScheme.onSurface, ancientGold);
    expect(dark.textTheme.bodyMedium?.color, ancientGold);
  });

  test('light theme text is not gold', () {
    expect(buildLightTheme().textTheme.bodyMedium?.color, isNot(ancientGold));
  });

  test('dark forui theme uses the gold foreground', () {
    expect(buildForuiTheme(Brightness.dark).colors.foreground, ancientGold);
    expect(
      buildForuiTheme(Brightness.light).colors.foreground,
      isNot(ancientGold),
    );
  });
}
