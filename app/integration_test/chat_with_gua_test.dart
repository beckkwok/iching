import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/models/gua.dart';
import 'package:app/screens/chat_screen.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/fake_llm_service.dart';
import 'package:app/services/gua_seeder.dart';
import 'package:app/widgets/gua_card.dart';

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

  Gua _findGuaByCode(int code) {
    // Fetch the seeded gua from DB to use in our fake LLM.
    // We'll use a static test gua instead since we can't easily query it here.
    return Gua(
      id: 1,
      guaCode: code,
      guaName: '乾 (Qián)',
      guaContent: '上卦乾（天），下卦乾（天）',
      guaSummary: 'Strength, creativity, initiative. The creative power of the universe.',
      source: 'classical',
    );
  }

  testWidgets('system response with Gua shows GuaCard widget',
      (tester) async {
    // Configure fake LLM to produce a gua
    fakeLlm.willProduceGua(_findGuaByCode(1));

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send a message that triggers gua generation
    await tester.enterText(find.byType(TextField), 'I need guidance');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // GuaCard should be rendered in the response bubble
    expect(find.byType(GuaCard), findsOneWidget);

    // The gua name and code should be visible
    expect(find.textContaining('Gua 1'), findsOneWidget);
    expect(find.textContaining('乾 (Qián)'), findsOneWidget);
  });

  testWidgets('subsequent messages without gua do not show GuaCard',
      (tester) async {
    // First message produces a gua
    fakeLlm.willProduceGua(_findGuaByCode(1));

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // First message with gua
    await tester.enterText(find.byType(TextField), 'I need guidance');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.byType(GuaCard), findsOneWidget);

    // Second message without gua (fakeLlm won't produce another gua)
    await tester.enterText(find.byType(TextField), 'Tell me more');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    // There should still be exactly one GuaCard (from the first response)
    expect(find.byType(GuaCard), findsOneWidget);
  });
}
