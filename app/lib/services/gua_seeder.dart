import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/gua.dart';
import 'database_service.dart';

/// Seeds the Gua table from individual hexagram JSON files.
///
/// Each hexagram lives in its own asset file `assets/hexagrams/gua_<n>.json`.
/// This seeder loads whatever files exist and inserts only hexagrams that are
/// not already present, so adding new files later only seeds the missing ones.
class GuaSeeder {
  final DatabaseService _db;
  final String _assetPrefix;
  final Future<String?> Function(int code)? _loader;

  GuaSeeder(
    this._db, {
    String assetPrefix = 'assets/hexagrams/gua_',
    Future<String?> Function(int code)? assetLoader,
  })  : _assetPrefix = assetPrefix,
        _loader = assetLoader;

  /// Seed any missing hexagrams. Returns the number of records inserted.
  Future<int> seedIfNeeded() async {
    final existing = await _db.getAllGua();
    final existingCodes = existing.map((g) => g.guaCode).toSet();

    int inserted = 0;
    for (var code = 1; code <= 64; code++) {
      if (existingCodes.contains(code)) continue;
      final json = await _loadAsset(code);
      if (json == null) continue;
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final gua = Gua(
          guaCode: map['卦序'] as int? ?? code,
          guaName: map['卦名'] as String? ?? 'Gua $code',
          guaContent: json,
        );
        await _db.createGua(gua);
        inserted++;
      } catch (_) {
        // Skip malformed files.
      }
    }
    return inserted;
  }

  Future<String?> _loadAsset(int code) async {
    if (_loader != null) {
      return _loader!(code);
    }
    try {
      return await rootBundle.loadString('$_assetPrefix$code.json');
    } catch (_) {
      return null;
    }
  }
}
