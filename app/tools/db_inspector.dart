// ignore_for_file: avoid_print
//
// Run with: dart run tools/db_inspector.dart
// Dumps the current SQLite tables (gua + settings).
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Determine the database path (same logic as DatabaseService).
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final dbPath = p.join(home, 'AppData', 'Roaming', 'iching', 'iching.db');

  print('Looking for database...');

  // Try multiple possible locations
  final candidates = [
    dbPath,
    p.join(home, 'iching.db'),
    'iching.db',
  ];

  String? foundPath;
  for (final candidate in candidates) {
    if (await File(candidate).exists()) {
      foundPath = candidate;
      break;
    }
  }

  if (foundPath == null) {
    print('Database file not found at any expected location.');
    print('The database is stored in the app\'s private data directory.');
    print('On Android: data/data/com.example.app/databases/iching.db');
    print('On emulator, use: adb shell to query.');
    print('');
    print('Creating an in-memory database to show the schema instead:');
  }

  final path = foundPath ?? inMemoryDatabasePath;
  final db = await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      // Schema only — won't run if file already exists.
      print('(Database did not exist — showing schema only)');
    },
  );

  // List settings
  print('\n═══════════════════════════════════════════');
  print('  SETTINGS');
  print('═══════════════════════════════════════════');
  final settings = await db.rawQuery('SELECT * FROM settings');
  if (settings.isEmpty) {
    print('  (no settings)');
  } else {
    for (final s in settings) {
      print('  ${s['key']} = ${s['value']}');
    }
  }

  // Count summary
  print('\n═══════════════════════════════════════════');
  print('  SUMMARY');
  print('═══════════════════════════════════════════');
  print('  Settings: ${settings.length}');
  print('');

  await db.close();
}
