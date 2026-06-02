import 'package:flutter/material.dart';
import 'screens/model_download_screen.dart';
import 'services/database_service.dart';
import 'services/gua_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt database initialisation across platforms.
  DatabaseService? db;
  try {
    db = await DatabaseService.create();
    if (db != null) {
      final seeder = GuaSeeder(db);
      await seeder.seedIfNeeded();
    }
  } catch (e) {
    db = null;
  }

  runApp(MyApp(databaseService: db));
}

class MyApp extends StatelessWidget {
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
      home: ModelDownloadScreen(databaseService: databaseService),
    );
  }
}
