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

  testWidgets('chat screen shows welcome message on load', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome'), findsOneWidget);
    expect(find.textContaining('Tell me what is on your mind'),
        findsOneWidget);
  });

  testWidgets('sending a message creates user bubble and receives response',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'I feel uncertain');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('I feel uncertain'), findsOneWidget);
    expect(find.textContaining('Thank you for sharing'), findsOneWidget);
  });
}
