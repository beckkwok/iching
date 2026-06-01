import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/data/hexagram_data.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/gua_seeder.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseService db;
  late GuaSeeder seeder;

  setUp(() async {
    try {
      await deleteDatabase(inMemoryDatabasePath);
    } catch (_) {}
    db = DatabaseService(databasePath: inMemoryDatabasePath);
    seeder = GuaSeeder(db);
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

    test('all hexagram data entries have required fields', () async {
      for (final entry in HexagramData.all) {
        expect(entry['gua_code'], isA<int>());
        expect(entry['gua_name'], isA<String>());
        expect(entry['gua_content'], isA<String>());
        expect(entry['gua_summary'], isA<String>());
        expect(entry['source'], isA<String>());
      }
    });

    test('gua codes are 1 through 64 without gaps', () async {
      final codes = HexagramData.all
          .map((e) => e['gua_code'] as int)
          .toList()
        ..sort();
      expect(codes, List.generate(64, (i) => i + 1));
    });

    test('all sources are "classical"', () async {
      for (final entry in HexagramData.all) {
        expect(entry['source'], 'classical');
      }
    });

    test('seeded gua can be retrieved by code order', () async {
      await seeder.seedIfNeeded();
      final all = await db.getAllGua();

      // They should be in insertion order (1..64)
      for (int i = 0; i < 64; i++) {
        expect(all[i].guaCode, i + 1);
        expect(all[i].guaName, isNotEmpty);
        expect(all[i].guaContent, isNotEmpty);
        expect(all[i].guaSummary, isNotEmpty);
      }
    });
  });
}
