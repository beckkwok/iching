import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app/services/database_service.dart';
import 'package:app/services/gua_seeder.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('migration from v2 clears old gua rows so seeder re-seeds JSON',
      () async {
    final dbPath = ':memory:';
    // Simulate a legacy v2 DB: create with old schema then insert old-format
    // gua rows.
    final legacy = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 2),
    );
    await legacy.execute('''
      CREATE TABLE gua (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gua_code INTEGER NOT NULL,
        gua_name TEXT NOT NULL,
        gua_content TEXT NOT NULL,
        gua_summary TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');
    await legacy.insert('gua', {
      'gua_code': 51,
      'gua_name': '震 (Zhèn)',
      'gua_content': 'old plain text',
      'gua_summary': 'old summary',
      'source': 'classical',
    });
    await legacy.close();

    // Open via DatabaseService (runs v2→v4 migration), then re-seed.
    final service = DatabaseService(databasePath: dbPath);
    await service.database;
    expect(await service.getAllGua(), isEmpty,
        reason: 'v4 migration must clear stale gua rows');

    final seeder = GuaSeeder(service, assetLoader: (code) async {
      return code == 51
          ? '{"卦名":"震為雷","卦序":51,"卦象":"䷱（下震上震）"}'
          : null;
    });
    await seeder.seedIfNeeded();

    final all = await service.getAllGua();
    expect(all.length, 1);
    final gua51 = all.first;
    expect(gua51.guaName, '震為雷');
    expect(gua51.content, isNotNull);
    expect(gua51.content!.guaSymbol, '䷱（下震上震）');

    await service.close();
  });
}
