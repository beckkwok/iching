import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/gua.dart';

/// Service for all SQLite database operations.
///
/// In production, the database is stored at [defaultDatabasePath].
/// For testing, pass [databasePath] = `inMemoryDatabasePath`
/// (requires `sqflite_common_ffi` initialization).
class DatabaseService {
  static const String _conversationsTable = 'conversations';
  static const String _messagesTable = 'chat_messages';
  static const String _guaTable = 'gua';
  static const String _settingsTable = 'settings';

  /// The database version for migration tracking.
  static const int _databaseVersion = 4;

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
      CREATE TABLE $_conversationsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_gua_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_messagesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        sender TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (conversation_id) 
          REFERENCES $_conversationsTable(id) ON DELETE CASCADE
      )
    ''');

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
  // Conversation CRUD
  // ---------------------------------------------------------------------------

  /// Create a new conversation and return it with the generated [id].
  Future<Conversation> createConversation(String title) async {
    final db = await database;
    final now = DateTime.now();
    final map = <String, dynamic>{
      'title': title,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'last_gua_id': null,
    };
    final id = await db.insert(_conversationsTable, map);
    return Conversation(
      id: id,
      title: title,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Return all conversations ordered by most recently updated first.
  Future<List<Conversation>> getAllConversations() async {
    final db = await database;
    final rows = await db.query(
      _conversationsTable,
      orderBy: 'updated_at DESC',
    );
    return rows.map((row) => Conversation.fromMap(row)).toList();
  }

  /// Get a single conversation by [id], or `null` if not found.
  Future<Conversation?> getConversation(int id) async {
    final db = await database;
    final rows = await db.query(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Conversation.fromMap(rows.first);
  }

  /// Update an existing conversation's title, updated_at, and last_gua_id.
  Future<void> updateConversation(Conversation conversation) async {
    final db = await database;
    await db.update(
      _conversationsTable,
      conversation.toMap(),
      where: 'id = ?',
      whereArgs: [conversation.id],
    );
  }

  /// Delete a conversation and all its messages (via CASCADE).
  Future<void> deleteConversation(int id) async {
    final db = await database;
    // Manually delete messages first (some SQLite builds may not enforce FK)
    await db.delete(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      _conversationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // Chat Message CRUD
  // ---------------------------------------------------------------------------

  /// Add a message to a conversation and return it with [dbId] and
  /// [conversationId] populated. Also touches the parent conversation's
  /// [updatedAt].
  Future<ChatMessage> addMessage(
    int conversationId,
    ChatMessage message,
  ) async {
    final db = await database;

    final map = message.toMap();
    map['conversation_id'] = conversationId;
    // Remove any stale id from map (let DB auto-increment)
    map.remove('id');

    final id = await db.insert(_messagesTable, map);

    // Bump the conversation's updated_at
    await db.update(
      _conversationsTable,
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    return message.copyWith(dbId: id, conversationId: conversationId);
  }

  /// Get all messages for a conversation, oldest first.
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final db = await database;
    final rows = await db.query(
      _messagesTable,
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return rows.map((row) => ChatMessage.fromDbMap(row)).toList();
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
