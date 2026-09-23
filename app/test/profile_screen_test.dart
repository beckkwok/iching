import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/models/agent_memory.dart';
import 'package:app/models/consultation.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/services/database_service.dart';

/// A [DatabaseService] that returns fixed memory/consultations, avoiding the
/// real sqflite-ffi DB in widget tests.
class _FakeDb extends DatabaseService {
  _FakeDb({this.memory, this.consultations = const []})
      : super(databasePath: ':memory:');

  final AgentMemory? memory;
  final List<Consultation> consultations;

  @override
  Future<AgentMemory?> getAgentMemory() async => memory;

  @override
  Future<List<Consultation>> getConsultations() async => consultations;
}

void main() {
  testWidgets('shows an empty state when there is no memory', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(databaseService: _FakeDb())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No memory yet'), findsOneWidget);
  });

  testWidgets('shows the agent memory and last consultation', (tester) async {
    final db = _FakeDb(
      memory: AgentMemory(
        feeling: 'hopeful about a change',
        facts: ['considering a job change'],
        preferences: ['values stability'],
        updatedAt: DateTime(2026, 9, 23),
      ),
      consultations: [
        Consultation(
          question: 'Should I move?',
          hexagramCode: 46,
          hexagramName: '地風升',
          hexagramContent: '{}',
          explanation: 'A gentle reflection.',
          createdAt: DateTime(2026, 9, 23, 10, 30),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(databaseService: db)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Last consultation'), findsOneWidget);
    expect(find.text('地風升'), findsOneWidget);
    expect(find.text('Should I move?'), findsOneWidget);
    expect(find.text('Agent Memory'), findsOneWidget);
    expect(find.text('How you might feel'), findsOneWidget);
    expect(find.text('hopeful about a change'), findsOneWidget);
    expect(find.text('Facts about you'), findsOneWidget);
    expect(find.text('considering a job change'), findsOneWidget);
    expect(find.text('Your preferences'), findsOneWidget);
    expect(find.text('values stability'), findsOneWidget);
  });
}
