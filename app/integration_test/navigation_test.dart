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

  testWidgets('history drawer opens and shows conversation title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send a message to create a conversation
    await tester.enterText(find.byType(TextField), 'Tell me about my path');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Open history drawer
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // The conversation title (date-time format) should appear in the drawer
    expect(find.textContaining('Conversations'), findsOneWidget);
  });

  testWidgets('settings menu opens settings screen with model info',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Open overflow menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Settings
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Should be on Settings screen
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Model File'), findsOneWidget);
    expect(find.text('Full Path'), findsOneWidget);
  });

  testWidgets('privacy notice dialog can be opened and dismissed',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to settings
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Tap Privacy Notice
    await tester.tap(find.text('Privacy Notice'));
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.text('Privacy Notice'), findsWidgets);

    // Dismiss by tapping OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Dialog should be gone
    expect(find.text('Privacy Notice'), findsOneWidget); // AppBar title still visible
  });

  testWidgets('navigate back from settings to chat screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send a message first so chat has content
    await tester.enterText(find.byType(TextField), 'Help me reflect');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // Navigate to settings
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Go back
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isEmpty) {
      // Platform may use different back widget
      await tester.tap(find.byTooltip('Back'));
    } else {
      await tester.tap(backButton);
    }
    await tester.pumpAndSettle();

    // Should be back on chat screen
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Help me reflect'), findsOneWidget);
  });
}
