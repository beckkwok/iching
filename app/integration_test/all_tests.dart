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

  // ---------------------------------------------------------------------------
  // Chat flow tests
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Gua card tests
  // ---------------------------------------------------------------------------

  Gua _testGua(int code) {
    return Gua(
      id: code,
      guaCode: code,
      guaName: '乾 (Qián)',
      guaContent: '上卦乾（天），下卦乾（天）',
      guaSummary:
          'Strength, creativity, initiative. The creative power of the universe.',
      source: 'classical',
    );
  }

  testWidgets('system response with Gua shows GuaCard widget',
      (tester) async {
    fakeLlm.willProduceGua(_testGua(1));

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'I need guidance');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.byType(GuaCard), findsOneWidget);
    expect(find.textContaining('Gua 1'), findsOneWidget);
    expect(find.textContaining('乾 (Qián)'), findsOneWidget);
  });

  testWidgets('subsequent messages without Gua do not show extra GuaCard',
      (tester) async {
    fakeLlm.willProduceGua(_testGua(1));

    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'I need guidance');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.byType(GuaCard), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Tell me more');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.byType(GuaCard), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Navigation tests
  // ---------------------------------------------------------------------------

  testWidgets('history drawer opens and shows conversation title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Tell me about my path');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

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

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Privacy Notice'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });

  testWidgets('navigate back from settings to chat screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Help me reflect');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Back'));
    } else {
      await tester.tap(backButton);
    }
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Help me reflect'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Persistence tests
  // ---------------------------------------------------------------------------

  testWidgets('messages are persisted to DB after sending', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send one message
    await tester.enterText(find.byType(TextField), 'Feeling lost');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Feeling lost'), findsOneWidget);

    // Verify messages were persisted to DB
    final allConvs = await db.getAllConversations();
    expect(allConvs.length, 1);
    final msgs = await db.getMessages(allConvs[0].id!);
    expect(msgs.length, 3, reason: 'welcome + user + system message');
    expect(msgs[1].text, 'Feeling lost');
    expect(msgs[1].isUser, isTrue);
    expect(msgs[2].isSystem, isTrue);

    // Reload from history drawer and verify message still visible
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Feeling lost'), findsOneWidget);
  });

  testWidgets('reloading conversation from history shows past messages',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(databaseService: db, llmService: fakeLlm),
      ),
    );
    await tester.pumpAndSettle();

    // Send one message
    await tester.enterText(find.byType(TextField), 'First message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('First message'), findsOneWidget);

    // Reload from history drawer
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Message should still be visible
    expect(find.text('First message'), findsOneWidget);
  });
}
