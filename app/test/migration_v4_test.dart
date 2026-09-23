import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app/models/consultation.dart';
import 'package:app/services/database_service.dart';

String _tmpPath() =>
    p.join(Directory.systemTemp.path, 'iching_migration_${Random().nextInt(1 << 32)}.db');

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('migration from v5 drops the legacy gua table', () async {
    final path = _tmpPath();
    // Simulate a legacy v5 DB that still has a gua table (and settings).
    final legacy = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 5),
    );
    await legacy.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await legacy.execute('''
      CREATE TABLE gua (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gua_code INTEGER NOT NULL,
        gua_name TEXT NOT NULL,
        gua_content TEXT NOT NULL
      )
    ''');
    await legacy.insert('gua', {
      'gua_code': 1,
      'gua_name': '乾為天',
      'gua_content': '{"卦名":"乾為天","卦序":1}',
    });
    await legacy.insert('settings', {
      'key': 'language',
      'value': 'cn',
    });
    await legacy.close();

    // Opening via DatabaseService runs the migration (v5 → current).
    final service = DatabaseService(databasePath: path);
    final db = await service.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final names = tables.map((t) => t['name']).toSet();
    expect(names, isNot(contains('gua')));
    expect(names, contains('settings'));

    // Settings survive the migration.
    expect(await service.getSetting('language'), 'cn');

    await service.close();
    await File(path).delete();
  });

  test('migration from v7 adds the hexagram_content column', () async {
    final path = _tmpPath();
    // Simulate a v7 database created before hexagram_content was added.
    final legacy = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 7),
    );
    await legacy.execute('''
      CREATE TABLE consultations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        question_type TEXT,
        hexagram_code INTEGER NOT NULL,
        hexagram_name TEXT NOT NULL,
        explanation TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await legacy.insert('consultations', {
      'question': 'q',
      'hexagram_code': 1,
      'hexagram_name': '乾為天',
      'explanation': 'e',
      'created_at': '2026-01-01T00:00:00.000',
    });
    await legacy.close();

    final service = DatabaseService(databasePath: path);
    final db = await service.database;

    final columns = await db.rawQuery('PRAGMA table_info(consultations)');
    final names = columns.map((c) => c['name']).toSet();
    expect(names, contains('hexagram_content'));

    // Existing rows are preserved (with a default empty content).
    final consultations = await service.getConsultations();
    expect(consultations.length, 1);
    expect(consultations.first.hexagramContent, '');

    // New consultations can be created with content.
    await service.createConsultation(Consultation(
      question: 'q2',
      hexagramCode: 2,
      hexagramName: '坤為地',
      hexagramContent: '{}',
      explanation: 'e2',
      createdAt: DateTime(2026, 1, 2),
    ));
    expect((await service.getConsultations()).length, 2);

    await service.close();
    await File(path).delete();
  });

  test('a fresh database has settings and consultations tables', () async {
    final path = _tmpPath();
    final service = DatabaseService(databasePath: path);
    final db = await service.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final names = tables.map((t) => t['name']).toSet();
    expect(names, contains('settings'));
    expect(names, contains('consultations'));
    expect(names, isNot(contains('gua')));

    await service.close();
    await File(path).delete();
  });
}
