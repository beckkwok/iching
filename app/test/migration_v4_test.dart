import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

    // Opening via DatabaseService runs the v5 → v6 migration.
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

  test('a fresh database has only the settings table', () async {
    final path = _tmpPath();
    final service = DatabaseService(databasePath: path);
    final db = await service.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final names = tables.map((t) => t['name']).toSet();
    expect(names, contains('settings'));
    expect(names, isNot(contains('gua')));

    await service.close();
    await File(path).delete();
  });
}
