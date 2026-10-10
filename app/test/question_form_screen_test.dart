import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/models/question_type.dart';
import 'package:app/screens/cast_result_screen.dart';
import 'package:app/screens/manual_cast_screen.dart';
import 'package:app/screens/question_form_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/hexagram_loader.dart';
import 'package:app/theme/app_theme.dart';
import 'package:app/widgets/glass_card.dart';

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

  QuestionFormScreen buildForm() => QuestionFormScreen(
        databaseService: db,
        guaGenerator: generator,
      );

  /// The medallion made the form taller than the test viewport, so the
  /// submit button must be scrolled into view before tapping.
  Future<void> tapSubmit(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
  }

  testWidgets('question form shows type selector, text box and submit button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    expect(find.text('What would you like to ask the I-Ching?'), findsOneWidget);
    expect(find.text('Question type'), findsOneWidget);
    expect(find.text('Your question'), findsOneWidget);
    expect(find.text('Submit Question'), findsOneWidget);
    expect(find.text('Casting method'), findsOneWidget);
    expect(find.text('Quick Generate'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<QuestionType>), findsOneWidget);
    expect(find.byKey(const ValueKey('method-quick')), findsOneWidget);
    expect(find.byKey(const ValueKey('method-manual')), findsOneWidget);
  });

  testWidgets('casting method defaults to quick generate', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('method-quick')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('method-manual')),
        matching: find.byIcon(Icons.tune),
      ),
      findsOneWidget,
    );
  });

  testWidgets('casting pills use gold styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    final quick = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('method-quick')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final quickDeco = quick.decoration! as BoxDecoration;
    final gradient = quickDeco.gradient! as LinearGradient;
    expect(gradient.colors, [champagneGold, bronzeGold]);

    final manual = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byKey(const ValueKey('method-manual')),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final manualDeco = manual.decoration! as BoxDecoration;
    expect(manualDeco.color, Colors.transparent);
    expect(
      (manualDeco.border! as Border).top.color,
      champagneGold.withValues(alpha: 0.6),
    );
  });

  testWidgets('form fields sit inside a glass card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    expect(find.byType(GlassCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(TextFormField),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(DropdownButtonFormField<QuestionType>),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the medallion emblem', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('glass card uses obsidian gradient fill in dark mode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: buildForm(),
      ),
    );

    final matches = find.descendant(
      of: find.byType(GlassCard),
      matching: find.byType(Container),
    );
    final card = matches.evaluate().map((e) => e.widget as Container).singleWhere(
      (c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.gradient is LinearGradient &&
            (decoration.gradient! as LinearGradient).colors.contains(
              const Color(0xFF13131A).withValues(alpha: 0.6),
            );
      },
    );
    final decoration = card.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, [
      const Color(0xFF1E1E28).withValues(alpha: 0.6),
      const Color(0xFF13131A).withValues(alpha: 0.6),
    ]);
    // Crisp champagne border.
    expect(
      (decoration.border! as Border).top.color,
      champagneGold.withValues(alpha: 0.45),
    );
  });

  testWidgets('submit without input shows validation errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: buildForm()),
    );

    await tapSubmit(tester, 'Submit Question');
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
    await tapSubmit(tester, 'Submit Question');
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

  testWidgets('submitting with manual method opens the manual cast screen',
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
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();

    await tapSubmit(tester, 'Submit Question');
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byType(ManualCastScreen), findsOneWidget);
    expect(find.text('Choose the six lines'), findsOneWidget);
  });

  testWidgets('first page renders Chinese when the locale is zh',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: buildForm(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('您想向易經請教什麼？'), findsOneWidget);
    expect(find.text('提交問題'), findsOneWidget);
    // The English labels are gone.
    expect(find.text('Submit Question'), findsNothing);
  });

  testWidgets('question category is localized through the consultation flow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: buildForm(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<QuestionType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('事業成就').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '我應該接受新工作嗎？');
    await tapSubmit(tester, '提交問題');

    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 200));

    final cast = tester.widget<CastResultScreen>(find.byType(CastResultScreen));
    expect(cast.questionTypeLabel, '事業成就');
  });

}
