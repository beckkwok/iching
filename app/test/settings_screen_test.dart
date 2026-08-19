import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/models/language_preference.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;

  setUp(() async {
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
    db = DatabaseService(databasePath: inMemoryDatabasePath);
    await db.database;
  });

  tearDown(() async {
    await db.close();
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
  });

  Future<void> _pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(databaseService: db)),
    );
    // Let the async DB reads (model info + language) complete.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('language selector shows both options', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('中文 (Chinese)'), findsOneWidget);
  });

  testWidgets('selecting Chinese persists the language setting',
      (tester) async {
    await _pumpSettings(tester);

    await tester.tap(find.text('中文 (Chinese)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Let the async DB write complete before verifying.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    final saved = await tester.runAsync(
      () => db.getSetting(LanguagePreference.settingsKey),
    );
    expect(saved, 'cn');
  });

  testWidgets('language selector reflects a saved preference', (tester) async {
    await tester.runAsync(
      () => db.setSetting(LanguagePreference.settingsKey, 'cn'),
    );
    await _pumpSettings(tester);

    final group = tester.widget<RadioGroup<LanguagePreference>>(
      find.byType(RadioGroup<LanguagePreference>),
    );
    expect(group.groupValue, LanguagePreference.chinese);

    final radio = tester.widget<RadioListTile<LanguagePreference>>(
      find.byWidgetPredicate(
        (w) =>
            w is RadioListTile<LanguagePreference> &&
            w.value == LanguagePreference.chinese,
      ),
    );
    expect(radio.value, LanguagePreference.chinese);
  });
}
