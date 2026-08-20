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
    id: 46,
    guaCode: 46,
    guaName: '地風升',
    guaContent: _gua46Json,
  );
}

void main() {
  testWidgets('detail screen renders header card with name and sequence',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramDetailScreen(gua: _gua46())),
    );

    expect(find.text('第46卦'), findsOneWidget);
    expect(find.text('地風升'), findsWidgets);
    expect(find.text('䷭（下巽上坤）'), findsOneWidget);
  });

  testWidgets('detail screen renders all section cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramDetailScreen(gua: _gua46())),
    );
    await tester.pumpAndSettle();

    expect(find.text('卦辭'), findsOneWidget);
    expect(find.text('彖傳'), findsOneWidget);
    expect(find.text('大象傳'), findsOneWidget);
    expect(find.text('爻辭'), findsOneWidget);

    // Scroll to reveal the lower sections.
    await tester.scrollUntilVisible(
      find.text('備註'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('象徵意義'), findsOneWidget);
    expect(find.text('不同人解讀'), findsOneWidget);
    expect(find.text('備註'), findsOneWidget);
  });

  testWidgets('detail screen shows line details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramDetailScreen(gua: _gua46())),
    );
    await tester.pumpAndSettle();

    expect(find.text('初六'), findsOneWidget);
    expect(find.text('允升，大吉。'), findsOneWidget);
    expect(find.text('九二'), findsOneWidget);
    expect(find.textContaining('小象傳'), findsNWidgets(2));
  });

  testWidgets('detail screen shows symbolic meaning and interpretations',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HexagramDetailScreen(gua: _gua46())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('備註'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('基本卦象'), findsOneWidget);
    expect(find.text('主要象徵'), findsOneWidget);
    expect(find.text('生活與占事常見象徵'), findsOneWidget);
    expect(find.text('總結'), findsOneWidget);
    expect(find.textContaining('地風升象徵樹木'), findsOneWidget);
    expect(find.text('程頤（伊川易傳）'), findsOneWidget);
    expect(find.textContaining('卦辭解讀'), findsOneWidget);
  });

  testWidgets('detail screen handles unparseable gua content gracefully',
      (tester) async {
    final bad = Gua(id: 99, guaCode: 99, guaName: 'Bad', guaContent: 'not json');
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
