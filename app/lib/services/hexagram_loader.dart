import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/gua.dart';

/// Loads the 64 hexagrams directly from bundled JSON assets.
///
/// Each hexagram lives in its own asset file `assets/hexagrams/gua_<n>.json`.
/// This replaces the old SQLite `gua` table — the hexagrams are now read
/// straight from assets, so there is no seeding step.
class HexagramLoader {
  final String _assetPrefix;
  final Future<String?> Function(int code)? _loader;

  HexagramLoader([
    this._loader,
    this._assetPrefix = 'assets/hexagrams/gua_',
  ]);

  Future<String?> _loadAsset(int code) async {
    if (_loader != null) return _loader(code);
    try {
      return await rootBundle.loadString('$_assetPrefix$code.json');
    } catch (_) {
      return null;
    }
  }

  /// Parse [json] (the raw content of a `gua_<n>.json` file) into a [Gua].
  ///
  /// Returns `null` if the JSON is malformed.
  Gua? _parse(int code, String json) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Gua(
        guaCode: map['卦序'] as int? ?? code,
        guaName: map['卦名'] as String? ?? 'Gua $code',
        guaContent: json,
      );
    } catch (_) {
      return null;
    }
  }

  /// Load all 64 hexagrams, sorted by guaCode (1..64). Hexagrams whose asset
  /// file is missing or malformed are skipped.
  Future<List<Gua>> loadAll() async {
    final guaList = <Gua>[];
    for (var code = 1; code <= 64; code++) {
      final json = await _loadAsset(code);
      if (json == null) continue;
      final gua = _parse(code, json);
      if (gua != null) guaList.add(gua);
    }
    guaList.sort((a, b) => a.guaCode.compareTo(b.guaCode));
    return guaList;
  }

  /// Load a single hexagram by [guaCode], or `null` if the asset is missing
  /// or malformed.
  Future<Gua?> loadByCode(int guaCode) async {
    final json = await _loadAsset(guaCode);
    if (json == null) return null;
    return _parse(guaCode, json);
  }
}
