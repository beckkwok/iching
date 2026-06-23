import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/screens/chat_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/fake_llm_service.dart';
import 'package:app/services/gua_seeder.dart';

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
    final seeder = GuaSeeder(db);
    await seeder.seedIfNeeded();
    fakeLlm = FakeLlmService();
  });

  tearDown(() async {
    await db.close();
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
  });

  testWidgets('messages persist in DB and survive reload from history',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send first message
    await tester.enterText(find.byType(TextField), 'Feeling lost');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Feeling lost'), findsOneWidget);

    // Send second message
    await tester.enterText(find.byType(TextField), 'Need direction');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Need direction'), findsOneWidget);

    // Open history drawer and tap the conversation to reload
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // Find the conversation list item and tap it
    // The drawer shows conversation titles (date-time format)
    final convTitle = find.byType(ListTile).first;
    await tester.tap(convTitle);
    await tester.pumpAndSettle();

    // Both messages should still be visible after reload
    expect(find.text('Feeling lost'), findsOneWidget);
    expect(find.text('Need direction'), findsOneWidget);
  });

  testWidgets('new message after reload appends correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send and reload
    await tester.enterText(find.byType(TextField), 'First message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Send another message
    await tester.enterText(find.byType(TextField), 'Appended message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Both messages should be visible
    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Appended message'), findsOneWidget);
  });
}
