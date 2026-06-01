import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'services/database_service.dart';
import 'services/gua_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt database initialisation. On unsupported platforms (e.g. web)
  // sqflite will throw — the app gracefully falls back to in-memory mode
  // where messages are not persisted across sessions.
  DatabaseService? db;
  try {
    db = DatabaseService();
    await db.database; // ensure tables exist
    final seeder = GuaSeeder(db);
    await seeder.seedIfNeeded();
  } catch (e) {
    // Database unavailable — app runs without persistence.
    db = null;
  }

  runApp(MyApp(databaseService: db));
}

class MyApp extends StatelessWidget {
  /// Null on platforms where SQLite is not available (e.g. web).
  final DatabaseService? databaseService;

  const MyApp({super.key, required this.databaseService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Ching',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChatScreen(databaseService: databaseService),
    );
  }
}
