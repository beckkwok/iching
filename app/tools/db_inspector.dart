/// Run with: dart run tools/db_inspector.dart
///
/// Dumps all conversations and chat messages from the SQLite database.
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Determine the database path (same logic as DatabaseService).
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
  final dbPath = p.join(home, 'AppData', 'Roaming', 'iching', 'iching.db');

  // Also check the standard Flutter databases path.
  final defaultDbDir = p.join(home, 'Documents', 'iching', 'app', 'build', 'flutter_assets');
  
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

  // List conversations
  print('\n═══════════════════════════════════════════');
  print('  CONVERSATIONS');
  print('═══════════════════════════════════════════');
  final conversations = await db.rawQuery('SELECT * FROM conversations');
  if (conversations.isEmpty) {
    print('  (no conversations)');
  } else {
    for (final c in conversations) {
      print('  [${c['id']}] ${c['title']}');
      print('       created: ${c['created_at']}');
      print('       updated: ${c['updated_at']}');
      print('       last_gua_id: ${c['last_gua_id']}');
      print('');
    }
  }

  // List chat messages
  print('\n═══════════════════════════════════════════');
  print('  CHAT MESSAGES');
  print('═══════════════════════════════════════════');
  final messages = await db.rawQuery('''
    SELECT cm.*, c.title as conv_title
    FROM chat_messages cm
    JOIN conversations c ON cm.conversation_id = c.id
    ORDER BY cm.conversation_id, cm.timestamp
  ''');
  if (messages.isEmpty) {
    print('  (no messages)');
  } else {
    for (final m in messages) {
      final sender = m['sender'] == 'user' ? '👤' : '✨';
      print('  $sender [conv ${m['conversation_id']}] '
          '${m['message']}');
      print('       at: ${m['timestamp']}');
      print('');
    }
  }

  // Count summary
  print('\n═══════════════════════════════════════════');
  print('  SUMMARY');
  print('═══════════════════════════════════════════');
  print('  Conversations: ${conversations.length}');
  print('  Chat messages: ${messages.length}');
  print('');

  await db.close();
}
