import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  // Gua tests
  // ---------------------------------------------------------------------------

  group('Gua', () {
    const sampleContent =
        '{"卦名":"乾 (Qián)","卦序":1,"卦象":"䷀（下乾上乾）","卦辭":"乾：元亨利貞。",'
        '"彖傳":"大哉乾元","大象傳":"天行健，君子以自強不息。",'
        '"爻辭":[],"象徵意義":{"基本卦象":{},"主要象徵":[],"生活與占事常見象徵":{},'
        '"總結":"The creative power of the universe."},'
        '"不同人解讀":[],"備註":""}';

    Gua createSampleGua() {
      return Gua(
        guaCode: 1,
        guaName: '乾 (Qián)',
        guaContent: sampleContent,
      );
    }

    test('createGua inserts and returns a Gua with id', () async {
      final gua = createSampleGua();
      final saved = await service.createGua(gua);

      expect(saved.id, isNotNull);
      expect(saved.guaCode, 1);
      expect(saved.guaName, '乾 (Qián)');
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
      expect(fetched.guaName, '乾 (Qián)');
    });

    test('getAllGua returns all Gua records', () async {
      final gua1 = createSampleGua();
      final gua2 = Gua(
        guaCode: 2,
        guaName: '坤 (Kūn)',
        guaContent:
            '{"卦名":"坤 (Kūn)","卦序":2,"卦象":"䷁（下坤上坤）","卦辭":"坤：元亨，利牝馬之貞。"}',
      );

      await service.createGua(gua1);
      await service.createGua(gua2);

      final all = await service.getAllGua();
      expect(all.length, 2);
    });

    test('Gua content parses into HexagramContent', () async {
      final gua = createSampleGua();
      final content = gua.content;
      expect(content, isNotNull);
      expect(content!.guaName, '乾 (Qián)');
      expect(content.guaSequence, 1);
      expect(
        content.symbolicMeaning.summary,
        'The creative power of the universe.',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Settings tests
  // ---------------------------------------------------------------------------

  group('Settings', () {
    test('getSetting returns null for a missing key', () async {
      final value = await service.getSetting('nonexistent');
      expect(value, isNull);
    });

    test('setSetting and getSetting round-trip a value', () async {
      await service.setSetting('theme', 'dark');
      final value = await service.getSetting('theme');
      expect(value, 'dark');
    });

    test('setSetting overwrites an existing value', () async {
      await service.setSetting('theme', 'light');
      await service.setSetting('theme', 'dark');
      final value = await service.getSetting('theme');
      expect(value, 'dark');
    });

    test('setSetting with null removes the key', () async {
      await service.setSetting('theme', 'dark');
      await service.setSetting('theme', null);
      final value = await service.getSetting('theme');
      expect(value, isNull);
    });

    test('multiple settings are stored independently', () async {
      await service.setSetting('key1', 'value1');
      await service.setSetting('key2', 'value2');

      expect(await service.getSetting('key1'), 'value1');
      expect(await service.getSetting('key2'), 'value2');
    });
  });
}
