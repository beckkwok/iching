import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/consultation.dart';
import 'package:app/models/yao_line_type.dart';
import 'package:app/screens/consultation_detail_screen.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/widgets/hexagram_view.dart';

/// A [DatabaseService] that returns a fixed list of consultations, avoiding
/// the real sqflite-ffi DB in widget tests.
class _FakeDb extends DatabaseService {
  _FakeDb(this._items) : super(databasePath: ':memory:');

  final List<Consultation> _items;
  final List<int> deletedIds = [];

  @override
  Future<List<Consultation>> getConsultations() async => _items;

  @override
  Future<void> deleteConsultation(int id) async {
    deletedIds.add(id);
    _items.removeWhere((c) => c.id == id);
  }
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
  id: 1,
  question: 'Should I move?',
  questionTypeLabel: 'Timing',
  hexagramCode: 46,
  hexagramName: '地風升',
  hexagramContent: _content46,
  explanation: 'A gentle reflection.',
  lineTypes: const [
    YaoLineType.oldYang,
    YaoLineType.youngYin,
    YaoLineType.youngYang,
    YaoLineType.oldYin,
    YaoLineType.youngYang,
    YaoLineType.youngYin,
  ],
  changedHexagramCode: 12,
  changedHexagramName: '天地否',
  changedHexagramContent: '{"卦名":"天地否","卦序":12}',
  reaction: 'love',
  comment: 'I feel hopeful about the move.',
  createdAt: DateTime(2026, 9, 23, 10, 30),
);

void main() {
  testWidgets('shows an empty state when there are no consultations', (
    tester,
  ) async {
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
    // Changed hexagram (issue #47): name + a small line figure in the card.
    expect(find.textContaining('天地否'), findsOneWidget);
    expect(find.byType(HexagramView), findsOneWidget);
    // Feedback: the love reaction + the user's comment.
    expect(find.text('❤️'), findsOneWidget);
    expect(find.text('I feel hopeful about the move.'), findsOneWidget);
  });

  testWidgets('deleting a consultation removes it after confirmation', (
    tester,
  ) async {
    final db = _FakeDb([_consultation()]);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(databaseService: db)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete this entry?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(db.deletedIds, [1]);
    expect(find.textContaining('No consultations yet'), findsOneWidget);
  });

  testWidgets('tapping a consultation opens the full record', (tester) async {
    final db = _FakeDb([_consultation()]);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(databaseService: db)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('地風升'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsultationDetailScreen), findsOneWidget);
    // The full record: original + changed hexagram, explanation and feedback.
    expect(find.text('Hexagram 46'), findsOneWidget);
    expect(find.text('天地否'), findsOneWidget);
    // Original cast figure + changed-hexagram figure.
    expect(find.byType(HexagramView), findsNWidgets(2));
    expect(find.text('A gentle reflection.'), findsOneWidget);
    expect(find.text('I feel hopeful about the move.'), findsOneWidget);
  });
}
