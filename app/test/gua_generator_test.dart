import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/services/database_service.dart';
import 'package:app/services/gua_generator.dart';
import 'package:app/services/gua_seeder.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late GuaGenerator generator;

  setUp(() async {
    db = DatabaseService(databasePath: ':memory:');
    await db.database;
    final seeder = GuaSeeder(db);
    await seeder.seedIfNeeded();
    generator = GuaGenerator(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('GuaGenerator', () {
    test('generateRandom returns a GenerationResult with randomCast method',
        () async {
      final result = await generator.generateRandom();

      expect(result, isA<GenerationResult>());
      expect(result.gua.guaCode, inInclusiveRange(1, 64));
      expect(result.method, GeneratorMethod.randomCast);
    });

    test('generateRandom produces different results', () async {
      final results = <int>{};
      for (int i = 0; i < 20; i++) {
        final result = await generator.generateRandom();
        results.add(result.gua.guaCode);
      }
      expect(results.length, greaterThan(1));
    });

    test('findInText detects gua by number with userRequested method',
        () async {
      final result = await generator.findInText('Tell me about gua 23');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 23);
      expect(result.method, GeneratorMethod.userRequested);
    });

    test('findInText detects gua by hexagram keyword', () async {
      final result = await generator.findInText('What does hexagram 1 mean?');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 1);
    });

    test('findInText detects gua by Chinese name', () async {
      final result = await generator.findInText('我想知道乾卦的含義');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 1);
    });

    test('findInText detects gua by pinyin', () async {
      final result = await generator.findInText('Tell me about qian');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 1);
    });

    test('findInText returns null for unrelated text', () async {
      final result = await generator.findInText(
        'I feel uncertain about my career path',
      );
      expect(result, isNull);
    });

    test('formatContext includes method header and gua details', () async {
      final result = await generator.generateRandom();
      final context = generator.formatContext(result);

      expect(context, contains('Hexagram'));
      expect(context, contains('gua code ${result.gua.guaCode}'));
      expect(context, contains(result.gua.guaName));
      expect(context, contains(result.gua.guaSummary));
      expect(context, contains(result.gua.guaContent));
      expect(context, contains(result.gua.source));
    });

    test('formatContext has different headers for different methods',
        () async {
      final gua = (await generator.generateRandom()).gua;

      final userReq = generator.formatContext(
          GenerationResult(gua: gua, method: GeneratorMethod.userRequested));
      final randomCast = generator.formatContext(
          GenerationResult(gua: gua, method: GeneratorMethod.randomCast));

      expect(userReq, isNot(equals(randomCast)));
      expect(userReq, contains('specifically asked'));
      expect(randomCast, contains('at the user\'s request'));
    });

    test('associateWithConversation updates lastGuaId', () async {
      final conv = await db.createConversation('Test gua');
      final result = await generator.generateRandom();

      await generator.associateWithConversation(conv.id!, result.gua);

      final updated = await db.getConversation(conv.id!);
      expect(updated!.lastGuaId, result.gua.id);
    });

    test('findInText detects gua by Chinese character 坤', () async {
      final result = await generator.findInText('坤卦怎麼說？');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 2);
    });

    test('findInText detects gua number with Chinese 卦 prefix', () async {
      final result = await generator.findInText('卦 42');
      expect(result, isNotNull);
      expect(result!.gua.guaCode, 42);
    });
  });
}
