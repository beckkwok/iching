import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/consultation.dart';
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
    final db = _FakeDb([
      Consultation(
        question: 'Should I move?',
        questionTypeLabel: 'Timing',
        hexagramCode: 46,
        hexagramName: '地風升',
        explanation: 'A gentle reflection.',
        createdAt: DateTime(2026, 9, 23, 10, 30),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: HistoryScreen(databaseService: db)),
    );
    await tester.pumpAndSettle();

    expect(find.text('地風升'), findsOneWidget);
    expect(find.text('Hexagram 46'), findsOneWidget);
    expect(find.text('Should I move?'), findsOneWidget);
    expect(find.textContaining('A gentle reflection'), findsOneWidget);
  });
}
