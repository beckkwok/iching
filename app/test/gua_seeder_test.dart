import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/services/database_service.dart';
import 'package:app/services/gua_seeder.dart';

/// Generates a minimal-but-valid hexagram JSON blob for [code].
String fixtureJson(int code) {
  final names = {
    1: '乾 (Qián)',
    2: '坤 (Kūn)',
    64: '未濟 (Wèi Jì)',
  };
  final name = names[code] ?? 'Gua $code';
  return jsonEncode({
    '卦名': name,
    '卦序': code,
    '卦象': '䷀（下乾上乾）',
    '卦辭': '卦辭 $code',
    '彖傳': '彖傳 $code',
    '大象傳': '大象傳 $code',
    '爻辭': [
      {'爻位': '初六', '爻辭': '爻辭A', '小象傳': '小象A'},
      {'爻位': '九二', '爻辭': '爻辭B', '小象傳': '小象B'},
    ],
    '象徵意義': {
      '基本卦象': {'卦體': '下乾上乾', '自然取象': '天', '說明': '說明'},
      '主要象徵': [
        {'標題': '標題', '內容': '內容'},
      ],
      '生活與占事常見象徵': {'事業': '事業說明'},
      '總結': '總結 $code',
    },
    '不同人解讀': [
      {
        '解讀者': '程頤',
        '卦辭解讀': '卦辭解讀',
        '爻辭解讀': {'初六': '初六解讀'},
      },
    ],
    '備註': '備註 $code',
  });
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late GuaSeeder seeder;

  Future<String?> allLoader(int code) async => fixtureJson(code);

  setUp(() async {
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
    db = DatabaseService(databasePath: inMemoryDatabasePath);
    seeder = GuaSeeder(db, assetLoader: allLoader);
  });

  tearDown(() async {
    await db.close();
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
  });

  group('GuaSeeder', () {
    test('seedIfNeeded inserts all 64 hexagrams', () async {
      final count = await seeder.seedIfNeeded();

      expect(count, 64, reason: 'All 64 hexagrams should be inserted');

      final all = await db.getAllGua();
      expect(all.length, 64);

      // Verify first and last
      expect(all[0].guaCode, 1);
      expect(all[0].guaName, '乾 (Qián)');
      expect(all[64 - 1].guaCode, 64);
      expect(all[64 - 1].guaName, '未濟 (Wèi Jì)');
    });

    test('seedIfNeeded is idempotent (second call does nothing)', () async {
      await seeder.seedIfNeeded();
      final count2 = await seeder.seedIfNeeded();

      expect(count2, 0, reason: 'Second seed should insert nothing');

      final all = await db.getAllGua();
      expect(all.length, 64);
    });

    test('seeded gua_content is valid hexagram JSON', () async {
      await seeder.seedIfNeeded();
      final all = await db.getAllGua();
      for (final gua in all) {
        final content = gua.content;
        expect(content, isNotNull,
            reason: 'gua ${gua.guaCode} should have parseable JSON');
        expect(content!.guaSequence, gua.guaCode);
        expect(content.guaName, gua.guaName);
        expect(content.guaCi, isNotEmpty);
        expect(content.lines.length, 2);
        expect(content.interpretations.length, 1);
      }
    });

    test('gua codes are 1 through 64 without gaps', () async {
      await seeder.seedIfNeeded();
      final all = await db.getAllGua();
      final codes = all.map((g) => g.guaCode).toList()..sort();
      expect(codes, List.generate(64, (i) => i + 1));
    });

    test('seeder only inserts missing hexagrams', () async {
      // First seed all.
      await seeder.seedIfNeeded();

      // A seeder that only knows hexagram 1 should add nothing (all present).
      final limitedSeeder = GuaSeeder(
        db,
        assetLoader: (code) async => code == 1 ? fixtureJson(code) : null,
      );
      final count = await limitedSeeder.seedIfNeeded();
      expect(count, 0);
    });

    test('seeder fills gaps when only some files exist', () async {
      final partialSeeder = GuaSeeder(
        db,
        assetLoader: (code) async => code <= 3 ? fixtureJson(code) : null,
      );
      final count = await partialSeeder.seedIfNeeded();
      expect(count, 3);

      final all = await db.getAllGua();
      expect(all.length, 3);

      // Now full seeder adds the remaining 61.
      final remaining = await seeder.seedIfNeeded();
      expect(remaining, 61);
      expect((await db.getAllGua()).length, 64);
    });
  });
}
