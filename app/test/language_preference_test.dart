import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/language_preference.dart';

void main() {
  group('LanguagePreference', () {
    test('defaults to english', () {
      expect(LanguagePreference.fromCode(null), LanguagePreference.english);
      expect(LanguagePreference.fromCode(''), LanguagePreference.english);
      expect(LanguagePreference.fromCode('unknown'), LanguagePreference.english);
    });

    test('parses chinese code', () {
      expect(
        LanguagePreference.fromCode('cn'),
        LanguagePreference.chinese,
      );
    });

    test('parses english code', () {
      expect(
        LanguagePreference.fromCode('en'),
        LanguagePreference.english,
      );
    });

    test('codes round-trip', () {
      for (final pref in LanguagePreference.values) {
        expect(LanguagePreference.fromCode(pref.code), pref);
      }
    });
  });
}
