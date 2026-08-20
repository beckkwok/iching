import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/data/model_catalog.dart';
import 'package:app/screens/prompt_editor_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/llm_service.dart';

/// Minimal LlmService for prompt editor tests (avoids flutter_gemma).
class FakeForTestLlm extends LlmService {
  FakeForTestLlm() : super(modelInfo: ModelCatalog.all.first);
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

  testWidgets('shows editor with save and reset buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PromptEditorScreen(
          llmService: FakeForTestLlm(),
          databaseService: db,
        ),
      ),
    );
    // Let the async DB read complete.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('System Prompt'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('saving persists the prompt to the settings table',
      (tester) async {
    final llm = FakeForTestLlm();
    await tester.pumpWidget(
      MaterialApp(
        home: PromptEditorScreen(llmService: llm, databaseService: db),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(
      find.byType(TextField),
      'You are a warm I-Ching guide.',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    final saved = await tester.runAsync(
      () => db.getSetting(LlmService.systemPromptSettingsKey),
    );
    expect(saved, 'You are a warm I-Ching guide.');
    expect(llm.systemPrompt, 'You are a warm I-Ching guide.');
  });
}
