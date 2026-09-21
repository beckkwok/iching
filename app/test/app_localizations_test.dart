import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/l10n/locale_controller.dart';
import 'package:app/models/language_preference.dart';

void main() {
  group('AppLocalizations', () {
    test('returns English strings for the en locale', () {
      final l10n = AppLocalizations(const Locale('en'));

      expect(l10n.isChinese, isFalse);
      expect(l10n.appTitle, 'I-Ching Consultation');
      expect(l10n.submitQuestion, 'Submit Question');
      expect(l10n.interpretation, 'Interpretation');
    });

    test('returns Chinese strings for the zh locale', () {
      final l10n = AppLocalizations(const Locale('zh'));

      expect(l10n.isChinese, isTrue);
      expect(l10n.appTitle, '易經諮詢');
      expect(l10n.submitQuestion, '提交問題');
      expect(l10n.interpretation, '解讀');
    });

    test('interpolates values in both languages', () {
      final en = AppLocalizations(const Locale('en'));
      final zh = AppLocalizations(const Locale('zh'));

      expect(en.hexagramNumber(7), 'Hexagram 7');
      expect(zh.hexagramNumber(7), '第7卦');
      expect(en.downloadModelTitle('Qwen3'), 'Download Qwen3?');
      expect(zh.downloadModelTitle('Qwen3'), '下載 Qwen3？');
    });

    test('supports en and zh only', () {
      final codes = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      expect(codes, containsAll(['en', 'zh']));

      expect(AppLocalizations.delegate.isSupported(const Locale('en')), isTrue);
      expect(AppLocalizations.delegate.isSupported(const Locale('zh')), isTrue);
      expect(
        AppLocalizations.delegate.isSupported(const Locale('fr')),
        isFalse,
      );
    });
  });

  group('LocaleController', () {
    test('exposes the locale for the initial language', () {
      expect(
        LocaleController(LanguagePreference.english).locale,
        const Locale('en'),
      );
      expect(
        LocaleController(LanguagePreference.chinese).locale,
        const Locale('zh'),
      );
    });

    test('setLanguage updates the locale and notifies listeners once', () {
      final controller = LocaleController(LanguagePreference.english);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setLanguage(LanguagePreference.chinese);
      expect(controller.locale, const Locale('zh'));
      expect(notifications, 1);

      // Setting the same value again is a no-op.
      controller.setLanguage(LanguagePreference.chinese);
      expect(notifications, 1);
    });
  });
}
