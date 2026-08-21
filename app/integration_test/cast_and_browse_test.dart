import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/explanation_screen.dart';
import 'package:app/screens/hexagram_browser_screen.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/screens/question_form_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/fake_llm_service.dart';

/// End-to-end tests for the consultation flow:
/// 1. question form → cast result → hexagram detail → explanation
/// 2. browse hexagram grid → hexagram detail
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late FakeLlmService fakeLlm;

  setUp(() async {
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
    db = DatabaseService(databasePath: inMemoryDatabasePath);
    await db.database;
    fakeLlm = FakeLlmService();
  });

  tearDown(() async {
    await db.close();
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
  });

  Future<void> _fillQuestionForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: QuestionFormScreen(databaseService: db, llmService: fakeLlm)),
    );
    await tester.pumpAndSettle();

    // Select a question type.
    await tester.tap(find.byType(DropdownButtonFormField<QuestionType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Career Achievement').last);
    await tester.pumpAndSettle();

    // Enter the question text.
    await tester.enterText(
      find.byType(TextFormField),
      'Should I take the new job?',
    );

    // Submit.
    await tester.tap(find.text('Submit Question'));
    await tester.pumpAndSettle();
  }

  testWidgets('question form → cast result → hexagram detail → explanation',
      (tester) async {
    await _fillQuestionForm(tester);

    // Land on the cast result screen with the 卦象 and yao lines.
    expect(find.byType(CastResultScreen), findsOneWidget);
    expect(find.text('爻象'), findsOneWidget);
    expect(find.text('Tap for details'), findsOneWidget);
    expect(find.text('Get Explanation'), findsOneWidget);

    // Open the full hexagram detail from the tappable 卦象 card.
    await tester.tap(find.text('Tap for details'));
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsOneWidget);
    // Detail screen shows the detail sections.
    expect(find.text('卦辭'), findsOneWidget);

    // Close the detail screen → back to the cast result screen.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(CastResultScreen), findsOneWidget);

    // Get the one-shot explanation.
    await tester.tap(find.text('Get Explanation'));
    await tester.pumpAndSettle();

    expect(find.byType(ExplanationScreen), findsOneWidget);
    expect(find.text('Should I take the new job?'), findsOneWidget);
    expect(find.text('解讀'), findsOneWidget);
  });

  testWidgets('browse hexagram grid opens the detail screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramBrowserScreen()),
    );
    await tester.pumpAndSettle();

    // Grid is populated.
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Hexagrams'), findsOneWidget);

    // Tap the first hexagram card (第1卦 乾為天).
    await tester.tap(find.text('乾為天').first);
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsOneWidget);

    // Close back to the browser.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(HexagramBrowserScreen), findsOneWidget);
  });
}
