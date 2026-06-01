import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/models/chat_message.dart';
import 'package:app/models/conversation.dart';
import 'package:app/models/gua.dart';
import 'package:app/services/database_service.dart';

void main() {
  // Initialise FFI-based SQLite for unit testing (no emulator required).
  setUpAll(() {
    sqfliteFfiInit();
    // Set the global factory so openDatabase() uses the FFI implementation.
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService service;

  setUp(() async {
    // Delete any cached database to ensure each test starts clean.
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {
      // Ignore if no cached database exists.
    }
    service = DatabaseService(databasePath: inMemoryDatabasePath);
  });

  tearDown(() async {
    // Close and clean up after each test.
    await service.close();
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
  });

  // ---------------------------------------------------------------------------
  // Conversation tests
  // ---------------------------------------------------------------------------

  group('Conversation', () {
    test('createConversation inserts and returns a conversation with id',
        () async {
      final conv = await service.createConversation('My first reading');

      expect(conv.id, isNotNull);
      expect(conv.title, 'My first reading');
      expect(conv.lastGuaId, isNull);
    });

    test('getConversation returns null for missing id', () async {
      final conv = await service.getConversation(999);
      expect(conv, isNull);
    });

    test('getConversation returns the correct conversation', () async {
      final created = await service.createConversation('Test conv');
      final fetched = await service.getConversation(created.id!);

      expect(fetched, isNotNull);
      expect(fetched!.id, created.id);
      expect(fetched.title, 'Test conv');
    });

    test('getAllConversations returns all conversations ordered by updatedAt',
        () async {
      final conv1 = await service.createConversation('First');
      // Add a small delay so timestamps differ
      await Future.delayed(const Duration(milliseconds: 10));
      final conv2 = await service.createConversation('Second');

      final all = await service.getAllConversations();

      expect(all.length, 2);
      // Most recent first
      expect(all[0].id, conv2.id);
      expect(all[1].id, conv1.id);
    });

    test('updateConversation updates title and updatedAt', () async {
      final conv = await service.createConversation('Original title');
      // Wait so timestamps are distinguishable.
      await Future.delayed(const Duration(milliseconds: 10));
      final updated = conv.copyWith(
        title: 'Updated title',
        updatedAt: DateTime.now(),
        lastGuaId: 1,
      );
      await service.updateConversation(updated);

      final fetched = await service.getConversation(conv.id!);
      expect(fetched!.title, 'Updated title');
      expect(fetched.lastGuaId, 1);
      // The fetched updatedAt should be >= the one we wrote.
      expect(
        fetched.updatedAt.isAtSameMomentAs(updated.updatedAt) ||
            fetched.updatedAt.isAfter(updated.updatedAt),
        isTrue,
      );
    });

    test('deleteConversation removes the conversation', () async {
      final conv = await service.createConversation('To delete');
      await service.deleteConversation(conv.id!);

      final fetched = await service.getConversation(conv.id!);
      expect(fetched, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ChatMessage tests
  // ---------------------------------------------------------------------------

  group('ChatMessage', () {
    late Conversation conv;

    setUp(() async {
      conv = await service.createConversation('Chat test');
    });

    test('addMessage inserts a message and returns it with dbId', () async {
      final msg = ChatMessage(
        id: 'ui_1',
        text: 'Hello',
        sender: MessageSender.user,
      );
      final saved = await service.addMessage(conv.id!, msg);

      expect(saved.dbId, isNotNull);
      expect(saved.conversationId, conv.id);
      expect(saved.text, 'Hello');
      expect(saved.isUser, isTrue);
    });

    test('getMessages returns messages in timestamp order', () async {
      final msg1 = ChatMessage(
        id: 'ui_1',
        text: 'First',
        sender: MessageSender.user,
        timestamp: DateTime(2026, 1, 1, 10, 0, 0),
      );
      final msg2 = ChatMessage(
        id: 'ui_2',
        text: 'Second',
        sender: MessageSender.system,
        timestamp: DateTime(2026, 1, 1, 10, 0, 1),
      );

      await service.addMessage(conv.id!, msg2);
      await service.addMessage(conv.id!, msg1);

      final messages = await service.getMessages(conv.id!);
      expect(messages.length, 2);
      // Should be ordered by timestamp ASC regardless of insert order
      expect(messages[0].text, 'First');
      expect(messages[1].text, 'Second');
      expect(messages[0].isUser, isTrue);
      expect(messages[1].isSystem, isTrue);
    });

    test('addMessage updates conversation updatedAt', () async {
      final originalUpdatedAt = conv.updatedAt;

      // Wait a bit so timestamp differs
      await Future.delayed(const Duration(milliseconds: 10));

      final msg = ChatMessage(
        id: 'ui_1',
        text: 'A message',
        sender: MessageSender.user,
      );
      await service.addMessage(conv.id!, msg);

      final fetchedConv = await service.getConversation(conv.id!);
      expect(
        fetchedConv!.updatedAt.isAfter(originalUpdatedAt),
        isTrue,
      );
    });

    test('deleting conversation also deletes its messages', () async {
      final msg = ChatMessage(
        id: 'ui_1',
        text: 'Will be deleted',
        sender: MessageSender.user,
      );
      await service.addMessage(conv.id!, msg);

      await service.deleteConversation(conv.id!);

      final messages = await service.getMessages(conv.id!);
      expect(messages, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Gua tests
  // ---------------------------------------------------------------------------

  group('Gua', () {
    Gua createSampleGua() {
      return Gua(
        guaCode: 1,
        guaName: 'Qian (The Creative)',
        guaContent: 'The Qian hexagram consists of six unbroken lines...',
        guaSummary: 'Strength, creativity, initiative.',
        source: 'manual',
      );
    }

    test('createGua inserts and returns a Gua with id', () async {
      final gua = createSampleGua();
      final saved = await service.createGua(gua);

      expect(saved.id, isNotNull);
      expect(saved.guaCode, 1);
      expect(saved.guaName, 'Qian (The Creative)');
      expect(saved.source, 'manual');
    });

    test('getGua returns null for missing id', () async {
      final gua = await service.getGua(999);
      expect(gua, isNull);
    });

    test('getGua returns the correct Gua', () async {
      final gua = createSampleGua();
      final saved = await service.createGua(gua);
      final fetched = await service.getGua(saved.id!);

      expect(fetched, isNotNull);
      expect(fetched!.id, saved.id);
      expect(fetched.guaCode, 1);
      expect(fetched.guaName, 'Qian (The Creative)');
    });

    test('getAllGua returns all Gua records', () async {
      final gua1 = createSampleGua();
      final gua2 = Gua(
        guaCode: 2,
        guaName: 'Kun (The Receptive)',
        guaContent: 'The Kun hexagram consists of six broken lines...',
        guaSummary: 'Receptivity, nurturing, devotion.',
        source: 'manual',
      );

      await service.createGua(gua1);
      await service.createGua(gua2);

      final all = await service.getAllGua();
      expect(all.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Cross-entity relationship tests
  // ---------------------------------------------------------------------------

  group('Relationships', () {
    test('can associate a Gua with a conversation via lastGuaId', () async {
      final gua = Gua(
        guaCode: 15,
        guaName: 'Qian (Modesty)',
        guaContent: 'Modesty content...',
        guaSummary: 'Modesty summary.',
        source: 'random',
      );
      final savedGua = await service.createGua(gua);

      final conv = await service.createConversation('Modesty reading');
      final updated = conv.copyWith(lastGuaId: savedGua.id);
      await service.updateConversation(updated);

      final fetched = await service.getConversation(conv.id!);
      expect(fetched!.lastGuaId, savedGua.id);

      // Fetch the associated Gua via its id
      final associatedGua = await service.getGua(savedGua.id!);
      expect(associatedGua!.guaName, 'Qian (Modesty)');
    });

    test('multiple messages belong to the same conversation', () async {
      final conv = await service.createConversation('Multi message');

      await service.addMessage(
        conv.id!,
        ChatMessage(id: 'm1', text: 'Q1', sender: MessageSender.user),
      );
      await service.addMessage(
        conv.id!,
        ChatMessage(id: 'm2', text: 'A1', sender: MessageSender.system),
      );
      await service.addMessage(
        conv.id!,
        ChatMessage(id: 'm3', text: 'Q2', sender: MessageSender.user),
      );

      final messages = await service.getMessages(conv.id!);
      expect(messages.length, 3);
      expect(messages.every((m) => m.conversationId == conv.id), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Full-flow simulation: replicate what ChatScreen._handleSubmit does
  // ---------------------------------------------------------------------------

  group('Chat flow simulation', () {
    test('complete send-respond cycle persists both messages', () async {
      // 1. Create conversation with date-time title (as ChatScreen does).
      final now = DateTime.now();
      final title =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';
      final conv = await service.createConversation(title);
      expect(conv.id, isNotNull);
      expect(
        conv.title,
        matches(RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}')),
      );

      // 2. Persist user message.
      final userMsg = ChatMessage(
        id: 'ui_1',
        text: 'I feel uncertain about my path',
        sender: MessageSender.user,
      );
      final savedUser =
          await service.addMessage(conv.id!, userMsg);
      expect(savedUser.dbId, isNotNull);
      expect(savedUser.conversationId, conv.id);

      // 3. Persist system response (simulating the 600ms delay).
      final systemMsg = ChatMessage(
        id: 'ui_2',
        text: 'Thank you for sharing. The wisdom of the I-Ching '
            'may offer perspective on what you describe.',
        sender: MessageSender.system,
      );
      final savedSystem =
          await service.addMessage(conv.id!, systemMsg);
      expect(savedSystem.dbId, isNotNull);
      expect(savedSystem.conversationId, conv.id);

      // 4. Verify both messages in order.
      final messages = await service.getMessages(conv.id!);
      expect(messages.length, 2);
      expect(messages[0].text, 'I feel uncertain about my path');
      expect(messages[0].isUser, isTrue);
      expect(messages[1].isSystem, isTrue);
      expect(messages[1].text, contains('Thank you'));

      // 5. Verify conversation updatedAt was bumped.
      final updatedConv = await service.getConversation(conv.id!);
      expect(
        updatedConv!.updatedAt.isAfter(conv.updatedAt) ||
            updatedConv.updatedAt.isAtSameMomentAs(conv.updatedAt),
        isTrue,
      );
    });

    test('multiple messages accumulate in same conversation', () async {
      final conv = await service.createConversation('Multi msg flow');

      // Round 1: user + system
      await service.addMessage(
        conv.id!,
        ChatMessage(
            id: 'u1', text: 'First', sender: MessageSender.user),
      );
      await service.addMessage(
        conv.id!,
        ChatMessage(
            id: 's1',
            text: 'Response 1',
            sender: MessageSender.system),
      );

      // Round 2: user + system
      await service.addMessage(
        conv.id!,
        ChatMessage(
            id: 'u2', text: 'Second', sender: MessageSender.user),
      );
      await service.addMessage(
        conv.id!,
        ChatMessage(
            id: 's2',
            text: 'Response 2',
            sender: MessageSender.system),
      );

      final messages = await service.getMessages(conv.id!);
      expect(messages.length, 4);
      expect(messages[0].text, 'First');
      expect(messages[1].text, 'Response 1');
      expect(messages[2].text, 'Second');
      expect(messages[3].text, 'Response 2');

      // All messages share the conversation ID
      expect(
        messages.every((m) => m.conversationId == conv.id),
        isTrue,
      );
    });
  });
}
