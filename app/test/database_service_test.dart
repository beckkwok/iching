import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:app/models/consultation.dart';
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

  // ---------------------------------------------------------------------------
  // Consultation tests
  // ---------------------------------------------------------------------------

  group('Consultation', () {
    test('createConsultation and getConsultations round-trip', () async {
      final saved = await service.createConsultation(Consultation(
        question: 'Should I take the new job?',
        questionTypeLabel: 'Career Achievement',
        hexagramCode: 46,
        hexagramName: '地風升',
        explanation: 'A gentle reflection.',
        createdAt: DateTime(2026, 1, 2, 3, 4),
      ));

      expect(saved.id, isNotNull);

      final all = await service.getConsultations();
      expect(all.length, 1);
      expect(all.first.question, 'Should I take the new job?');
      expect(all.first.questionTypeLabel, 'Career Achievement');
      expect(all.first.hexagramCode, 46);
      expect(all.first.hexagramName, '地風升');
      expect(all.first.explanation, 'A gentle reflection.');
      expect(all.first.createdAt, DateTime(2026, 1, 2, 3, 4));
    });

    test('getConsultations returns most recent first', () async {
      await service.createConsultation(Consultation(
        question: 'first',
        hexagramCode: 1,
        hexagramName: '乾為天',
        explanation: 'e',
        createdAt: DateTime(2026, 1, 1),
      ));
      await service.createConsultation(Consultation(
        question: 'second',
        hexagramCode: 2,
        hexagramName: '坤為地',
        explanation: 'e',
        createdAt: DateTime(2026, 1, 2),
      ));

      final all = await service.getConsultations();
      expect(all.length, 2);
      expect(all.first.question, 'second');
      expect(all.last.question, 'first');
    });
  });
}
