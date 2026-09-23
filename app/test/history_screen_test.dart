import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/consultation.dart';
import 'package:app/screens/hexagram_detail_screen.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/services/database_service.dart';

/// A [DatabaseService] that returns a fixed list of consultations, avoiding
/// the real sqflite-ffi DB in widget tests.
class _FakeDb extends DatabaseService {
  _FakeDb(this._items) : super(databasePath: ':memory:');

  final List<Consultation> _items;

  @override
  Future<List<Consultation>> getConsultations() async => _items;
}

const _content46 = '''
{
  "卦名": "地風升",
  "卦序": 46,
  "卦象": "䷭（下巽上坤）",
  "卦辭": "升：元亨。",
  "彖傳": "",
  "大象傳": "",
  "爻辭": [],
  "象徵意義": {
    "基本卦象": {"卦體": "下巽上坤", "自然取象": "地中生木", "說明": "說明"},
    "主要象徵": [],
    "生活與占事常見象徵": {},
    "總結": "總結"
  },
  "不同人解讀": [],
  "備註": ""
}
''';

Consultation _consultation() => Consultation(
      question: 'Should I move?',
      questionTypeLabel: 'Timing',
      hexagramCode: 46,
      hexagramName: '地風升',
      hexagramContent: _content46,
      explanation: 'A gentle reflection.',
      rating: 4,
      comment: 'I feel hopeful about the move.',
      createdAt: DateTime(2026, 9, 23, 10, 30),
    );

void main() {
  testWidgets('shows an empty state when there are no consultations',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(databaseService: _FakeDb(const []))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No consultations yet'), findsOneWidget);
  });

  testWidgets('lists saved consultations', (tester) async {
    final db = _FakeDb([_consultation()]);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(databaseService: db)),
    );
    await tester.pumpAndSettle();

    expect(find.text('地風升'), findsOneWidget);
    expect(find.text('Hexagram 46'), findsOneWidget);
    expect(find.text('Should I move?'), findsOneWidget);
    expect(find.textContaining('A gentle reflection'), findsOneWidget);
    // Feedback: 4 filled stars + the user's comment.
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.text('I feel hopeful about the move.'), findsOneWidget);
  });

  testWidgets('tapping a consultation opens the hexagram detail',
      (tester) async {
    final db = _FakeDb([_consultation()]);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(databaseService: db)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('地風升'));
    await tester.pumpAndSettle();

    expect(find.byType(HexagramDetailScreen), findsOneWidget);
    expect(find.text('Hexagram 46'), findsOneWidget);
  });
}
