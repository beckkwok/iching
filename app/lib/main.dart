import 'package:flutter/material.dart';
import 'screens/model_selection_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Attempt database initialisation across platforms. The database only
  // stores settings now; hexagrams are loaded from JSON assets.
  DatabaseService? db;
  try {
    db = await DatabaseService.create();
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
      home: ModelSelectionScreen(databaseService: databaseService),
    );
  }
}
