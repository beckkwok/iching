import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import '../models/gua.dart';

/// Service for all SQLite database operations.
///
/// In production, the database is stored at [defaultDatabasePath].
/// For testing, pass [databasePath] = `inMemoryDatabasePath`
/// (requires `sqflite_common_ffi` initialization).
class DatabaseService {
  static const String _guaTable = 'gua';
  static const String _settingsTable = 'settings';

  /// The database version for migration tracking.
  static const int _databaseVersion = 5;

  /// Custom database path (used for in-memory testing).
  final String? _customPath;

  Database? _database;

  DatabaseService({String? databasePath}) : _customPath = databasePath;

  /// Attempt to create a [DatabaseService] on the current platform.
  ///
  /// Tries native sqflite (Android/iOS) first, then FFI (desktop).
  /// Returns `null` on platforms where no SQLite backend is available (web).
  static Future<DatabaseService?> create() async {
    // Try native sqflite (Android, iOS).
    try {
      final service = DatabaseService();
      await service.database;
      return service;
    } catch (_) {
      // Try FFI-based SQLite (Windows, macOS, Linux).
      try {
        sqfliteFfiInit();
        // ignore: avoid_print
        print('📁 Using FFI-based SQLite (desktop)');
        databaseFactory = databaseFactoryFfi;
        final service = DatabaseService();
        await service.database;
        return service;
      } catch (_) {
        // No SQLite backend available (web).
        // ignore: avoid_print
        print('📁 SQLite not available — running in-memory mode');
        return null;
      }
    }
  }

  /// The default file path for the production database.
  static Future<String> get defaultDatabasePath async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'iching.db');
  }

  /// Lazily initialised database instance.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Close the database connection. Call this when the service is no longer
  /// needed (e.g., in test tearDown).
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final path = _customPath ?? await defaultDatabasePath;
    // ignore: avoid_print
    print('📁 Database path: $path');
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_guaTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gua_code INTEGER NOT NULL,
        gua_name TEXT NOT NULL,
        gua_content TEXT NOT NULL
      )
    ''');

    await _createSettingsTable(db);
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 3) {
      await _dropGuaColumns(db);
    }
    if (oldVersion < 4) {
      // v3 → v4: the gua data format changed to JSON (卦序/卦象/卦名 inside
      // gua_content). Old rows store plain-text content that no longer parses,
      // so clear the table and let GuaSeeder re-seed from the JSON assets.
      await db.delete(_guaTable);
    }
    if (oldVersion < 5) {
      // v4 → v5: the chat-based flow was removed. Drop the conversation and
      // message tables entirely.
      await db.execute('DROP TABLE IF EXISTS chat_messages');
      await db.execute('DROP TABLE IF EXISTS conversations');
    }
  }

  /// v2 → v3: remove `gua_summary` and `source` from the gua table.
  /// SQLite 3.35+ supports ALTER TABLE DROP COLUMN; the bundled engine
  /// (sqlite3 3.53.2) does. Falls back to a full table rebuild otherwise.
  Future<void> _dropGuaColumns(Database db) async {
    try {
      await db.execute('ALTER TABLE $_guaTable DROP COLUMN gua_summary');
      await db.execute('ALTER TABLE $_guaTable DROP COLUMN source');
    } catch (_) {
      // Older SQLite without DROP COLUMN — rebuild the table.
      await db.execute('''
        CREATE TABLE ${_guaTable}_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gua_code INTEGER NOT NULL,
          gua_name TEXT NOT NULL,
          gua_content TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO ${_guaTable}_new (id, gua_code, gua_name, gua_content)
        SELECT id, gua_code, gua_name, gua_content FROM $_guaTable
      ''');
      await db.execute('DROP TABLE $_guaTable');
      await db.execute(
          'ALTER TABLE ${_guaTable}_new RENAME TO $_guaTable');
    }
  }

  // ---------------------------------------------------------------------------
  // Gua CRUD
  // ---------------------------------------------------------------------------

  /// Store a new Gua record and return it with the generated [id].
  Future<Gua> createGua(Gua gua) async {
    final db = await database;
    final map = gua.toMap();
    map.remove('id');
    final id = await db.insert(_guaTable, map);
    return gua.copyWith(id: id);
  }

  /// Get a single Gua by [id], or `null` if not found.
  Future<Gua?> getGua(int id) async {
    final db = await database;
    final rows = await db.query(
      _guaTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Gua.fromMap(rows.first);
  }

  /// Return all Gua records.
  Future<List<Gua>> getAllGua() async {
    final db = await database;
    final rows = await db.query(_guaTable);
    return rows.map((row) => Gua.fromMap(row)).toList();
  }

  // ---------------------------------------------------------------------------
  // Settings CRUD
  // ---------------------------------------------------------------------------

  /// Get a setting by [key], or `null` if not found.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      _settingsTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// Set a setting. If [value] is `null`, the key is deleted.
  Future<void> setSetting(String key, String? value) async {
    final db = await database;
    if (value == null) {
      await db.delete(
        _settingsTable,
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      await db.insert(
        _settingsTable,
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
