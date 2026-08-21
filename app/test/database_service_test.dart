import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
