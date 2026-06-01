import 'package:sqflite/sqflite.dart';
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

  /// The database version for migration tracking.
  static const int _databaseVersion = 1;

  /// Custom database path (used for in-memory testing).
  final String? _customPath;

  Database? _database;

  DatabaseService({String? databasePath}) : _customPath = databasePath;

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
        gua_content TEXT NOT NULL,
        gua_summary TEXT NOT NULL,
        source TEXT NOT NULL
      )
    ''');
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
}
