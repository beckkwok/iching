import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import '../models/consultation.dart';

/// Service for all SQLite database operations.
///
/// In production, the database is stored at [defaultDatabasePath].
/// For testing, pass [databasePath] = `inMemoryDatabasePath`
/// (requires `sqflite_common_ffi` initialization).
class DatabaseService {
  static const String _settingsTable = 'settings';
  static const String _consultationsTable = 'consultations';

  /// The database version for migration tracking.
  static const int _databaseVersion = 7;

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
    await _createSettingsTable(db);
    await _createConsultationsTable(db);
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _createConsultationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_consultationsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        question_type TEXT,
        hexagram_code INTEGER NOT NULL,
        hexagram_name TEXT NOT NULL,
        hexagram_content TEXT NOT NULL,
        explanation TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 6) {
      // v5 → v6: the `gua` table was removed in favour of loading the
      // hexagrams directly from JSON assets. Drop it if it still exists.
      await db.execute('DROP TABLE IF EXISTS gua');
    }
    if (oldVersion < 7) {
      // v6 → v7: add the consultations table (issue #8).
      await _createConsultationsTable(db);
    }
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

  // ---------------------------------------------------------------------------
  // Consultation CRUD
  // ---------------------------------------------------------------------------

  /// Store a new [Consultation] and return it with the generated [id].
  Future<Consultation> createConsultation(Consultation consultation) async {
    final db = await database;
    final map = consultation.toMap();
    map.remove('id');
    final id = await db.insert(_consultationsTable, map);
    return Consultation(
      id: id,
      question: consultation.question,
      questionTypeLabel: consultation.questionTypeLabel,
      hexagramCode: consultation.hexagramCode,
      hexagramName: consultation.hexagramName,
      hexagramContent: consultation.hexagramContent,
      explanation: consultation.explanation,
      createdAt: consultation.createdAt,
    );
  }

  /// Return all consultations, most recent first.
  Future<List<Consultation>> getConsultations() async {
    final db = await database;
    final rows = await db.query(_consultationsTable, orderBy: 'id DESC');
    return rows.map(Consultation.fromMap).toList();
  }
}
