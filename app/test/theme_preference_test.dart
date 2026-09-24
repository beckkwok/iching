import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/theme_preference.dart';

void main() {
  group('ThemePreference.fromCode', () {
    test('defaults to dark for null or unknown codes', () {
      expect(ThemePreference.fromCode(null), ThemePreference.dark);
      expect(ThemePreference.fromCode(''), ThemePreference.dark);
      expect(ThemePreference.fromCode('system'), ThemePreference.dark);
    });

    test('parses light', () {
      expect(ThemePreference.fromCode('light'), ThemePreference.light);
    });

    test('parses dark', () {
      expect(ThemePreference.fromCode('dark'), ThemePreference.dark);
    });
  });

  test('settingsKey is stable', () {
    expect(ThemePreference.settingsKey, 'theme_mode');
  });

  test('codes round-trip', () {
    for (final value in ThemePreference.values) {
      expect(ThemePreference.fromCode(value.code), value);
    }
  });
}
