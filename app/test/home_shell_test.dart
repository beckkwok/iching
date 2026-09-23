import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'package:app/models/agent_memory.dart';
import 'package:app/models/consultation.dart';
import 'package:app/screens/home_shell.dart';
import 'package:app/screens/history_screen.dart';
import 'package:app/screens/profile_screen.dart';
import 'package:app/screens/question_form_screen.dart';
import 'package:app/services/database_service.dart';

/// A [DatabaseService] with mutable memory, to verify the Profile tab reloads
/// when re-selected.
class _FakeDb extends DatabaseService {
  _FakeDb() : super(databasePath: ':memory:');

  AgentMemory? memory;

  @override
  Future<AgentMemory?> getAgentMemory() async => memory;

  @override
  Future<List<Consultation>> getConsultations() async => const [];
}

void main() {
  Widget app({DatabaseService? db}) => MaterialApp(
        builder: (context, child) => FTheme(
          data: FThemeData(touch: true, colors: FColors.neutralLight),
          child: child!,
        ),
        home: HomeShell(databaseService: db),
      );

  testWidgets('shows the five bottom-nav destinations', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (final label in ['History', 'Profile', 'Ask', 'Browse', 'Preference']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('starts on the Ask tab', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(QuestionFormScreen), findsOneWidget);
  });

  testWidgets('switching to History shows the History screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryScreen), findsOneWidget);
  });

  testWidgets('switching to Profile shows the Profile screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Profile tab reloads when re-selected', (tester) async {
    final db = _FakeDb();
    await tester.pumpWidget(app(db: db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No memory yet'), findsOneWidget);

    // Memory becomes available after a consultation.
    db.memory = AgentMemory(
      feeling: 'hopeful',
      facts: const ['a fact'],
      preferences: const [],
      updatedAt: DateTime(2026, 9, 23),
    );

    // Switch away and back — the Profile tab must reload.
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('hopeful'), findsOneWidget);
  });
}
