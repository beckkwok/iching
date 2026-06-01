import '../data/hexagram_data.dart';
import '../models/gua.dart';
import 'database_service.dart';

/// Seeds the Gua table with the 64 classical hexagrams.
///
/// This should be called once on first launch to populate the database.
/// It skips insertion if the table already has records.
class GuaSeeder {
  final DatabaseService _db;

  GuaSeeder(this._db);

  /// Seed the Gua table. Returns the number of new records inserted.
  Future<int> seedIfNeeded() async {
    final existing = await _db.getAllGua();
    if (existing.isNotEmpty) {
      return 0; // already seeded
    }

    int inserted = 0;
    for (final entry in HexagramData.all) {
      final gua = Gua(
        guaCode: entry['gua_code'] as int,
        guaName: entry['gua_name'] as String,
        guaContent: entry['gua_content'] as String,
        guaSummary: entry['gua_summary'] as String,
        source: entry['source'] as String,
      );
      await _db.createGua(gua);
      inserted++;
    }
    return inserted;
  }
}
