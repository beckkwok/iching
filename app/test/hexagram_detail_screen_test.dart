import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/gua.dart';
import 'package:app/screens/hexagram_detail_screen.dart';

/// A full hexagram JSON blob for gua 46 (地風升), mirroring the real asset.
const _gua46Json = '''
{
  "卦名": "地風升",
  "卦序": 46,
  "卦象": "䷭（下巽上坤）",
  "卦辭": "升：元亨，用見大人，勿恤，南征吉。",
  "彖傳": "柔以時升，巽而順。",
  "大象傳": "地中生木，升。君子以順德，積小以高大。",
  "爻辭": [
    {"爻位": "初六", "爻辭": "允升，大吉。", "小象傳": "允升大吉，上合志也。"},
    {"爻位": "九二", "爻辭": "孚乃利用禴，无咎。", "小象傳": "九二之孚，有喜也。"}
  ],
  "象徵意義": {
    "基本卦象": {
      "卦體": "下巽上坤（䷭）",
      "自然取象": "地中生木",
      "說明": "木從地中生出。"
    },
    "主要象徵": [
      {"標題": "升進、上升", "內容": "事物由下往上發展。"}
    ],
    "生活與占事常見象徵": {
      "事業地位": "逐步晉升。",
      "時機": "處於生長期。"
    },
    "總結": "地風升象徵樹木從地中自然向上生長。"
  },
  "不同人解讀": [
    {
      "解讀者": "程頤（伊川易傳）",
      "卦辭解讀": "升者，進而上也。",
      "爻辭解讀": {"初六": "允者，信從也。", "九二": "以誠信事上。"}
    }
  ],
  "備註": "卦辭以通行本《周易》為準。"
}
''';

Gua _gua46() {
  return Gua(
    guaCode: 46,
    guaName: '地風升',
    guaContent: _gua46Json,
  );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: HexagramDetailScreen(gua: _gua46())),
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, then taps it and settles the expansion.
Future<void> _expand(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('卦象 section is expanded by default', (tester) async {
    await _pump(tester);

    expect(find.text('Hexagram 46'), findsOneWidget);
    expect(find.text('地風升'), findsWidgets);
    expect(find.text('䷭（下巽上坤）'), findsOneWidget);
  });

  testWidgets('shows the top-level tree sections', (tester) async {
    await _pump(tester);

    for (final title in [
      'Hexagram',
      'Symbolic Meaning',
      'Interpretation',
      'Original Text',
      'Remarks',
    ]) {
      await _scrollTo(tester, find.text(title));
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('象徵意義 is expanded by default', (tester) async {
    await _pump(tester);

    expect(find.text('Basic Symbol'), findsOneWidget);
    expect(find.text('Main Symbols'), findsOneWidget);
    expect(find.text('Life & Divination Symbols'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.textContaining('地風升象徵樹木'), findsOneWidget);
  });

  testWidgets('其他的解釋 is collapsed until tapped', (tester) async {
    await _pump(tester);

    await _scrollTo(tester, find.text('Other Interpretations'));
    expect(find.text('Other Interpretations'), findsOneWidget);
    expect(find.text('程頤（伊川易傳）'), findsNothing);

    await _expand(tester, find.text('Other Interpretations'));
    expect(find.text('程頤（伊川易傳）'), findsOneWidget);

    await _expand(tester, find.text('程頤（伊川易傳）'));
    expect(find.textContaining('Judgment interpretation'), findsOneWidget);
  });

  testWidgets('原文 is collapsed and reveals 爻辭 when expanded',
      (tester) async {
    await _pump(tester);

    expect(find.text('初六'), findsNothing);

    await _expand(tester, find.text('Original Text'));
    expect(find.text('Line Texts'), findsOneWidget);
    // The 爻辭 tile itself is still collapsed.
    expect(find.text('初六'), findsNothing);

    await _expand(tester, find.text('Line Texts'));
    expect(find.text('初六'), findsOneWidget);
    expect(find.text('允升，大吉。'), findsOneWidget);
    expect(find.textContaining('Small Image'), findsNWidgets(2));
  });

  testWidgets('detail screen handles unparseable gua content gracefully',
      (tester) async {
    final bad = Gua(guaCode: 99, guaName: 'Bad', guaContent: 'not json');
    await tester.pumpWidget(
      MaterialApp(home: HexagramDetailScreen(gua: bad)),
    );

    expect(find.textContaining('Unable to read'), findsOneWidget);
  });

  testWidgets('close button pops the detail screen back to the previous screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HexagramDetailScreen(gua: _gua46()),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(HexagramDetailScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
