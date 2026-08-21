import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/question_form_screen.dart';
import 'package:app/screens/settings_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/hexagram_loader.dart';

/// Minimal valid hexagram JSON for [code].
String fixtureJson(int code) {
  return '''
  {
    "卦名": "卦$code",
    "卦序": $code,
    "卦象": "䷀（下乾上乾）",
    "卦辭": "卦辭 $code",
    "彖傳": "彖傳 $code",
    "大象傳": "大象傳 $code",
    "爻辭": [],
    "象徵意義": {
      "基本卦象": {"卦體": "下乾上乾", "自然取象": "天", "說明": "說明"},
      "主要象徵": [],
      "生活與占事常見象徵": {},
      "總結": "總結 $code"
    },
    "不同人解讀": [],
    "備註": ""
  }
  ''';
}

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

  final generator = GuaGenerator(HexagramLoader((code) async => fixtureJson(code)));
  final loader = HexagramLoader((code) async => fixtureJson(code));

  QuestionFormScreen buildForm() => QuestionFormScreen(
        databaseService: db,
        guaGenerator: generator,
        hexagramLoader: loader,
      );

  testWidgets('question form shows type selector, text box and submit button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    expect(find.text('What would you like to ask the I-Ching?'), findsOneWidget);
    expect(find.text('Question type'), findsOneWidget);
    expect(find.text('Your question'), findsOneWidget);
    expect(find.text('Submit Question'), findsOneWidget);
    expect(find.text('Help me to generate hexagram'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<QuestionType>), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });

  testWidgets('hexagram checkbox defaults to checked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);
  });

  testWidgets('submit without input shows validation errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    await tester.tap(find.text('Submit Question'));
    await tester.pumpAndSettle();

    expect(find.text('Please select a question type'), findsOneWidget);
    expect(find.text('Please enter your question'), findsOneWidget);
  });

  testWidgets('submitting with hexagram enabled opens the cast result screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    await tester.tap(find.byType(DropdownButtonFormField<QuestionType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Career Achievement').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Should I take the new job?',
    );
    await tester.tap(find.text('Submit Question'));
    // Let the async cast + DB reads complete.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CastResultScreen), findsOneWidget);
    expect(find.textContaining('卦'), findsWidgets);
  });

  testWidgets('submitting with hexagram disabled shows a hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    await tester.tap(find.byType(DropdownButtonFormField<QuestionType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Career Achievement').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'Should I take the new job?',
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit Question'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enable hexagram generation to begin your reading.'),
      findsOneWidget,
    );
    expect(find.byType(CastResultScreen), findsNothing);
  });

  testWidgets('settings menu opens the settings screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
