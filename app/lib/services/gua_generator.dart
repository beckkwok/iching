import 'dart:math';
import '../models/gua.dart';
import 'database_service.dart';

/// How a hexagram was generated. Each method implies a different framing
/// for the LLM interpretation prompt.
enum GeneratorMethod {
  /// User explicitly named a hexagram (by name, number, or pinyin).
  userRequested,

  /// System randomly generated a hexagram with user consent.
  randomCast,

  /// System randomly generated for the first interaction before asking.
  automatic,
}

/// Result of a Gua generation or lookup.
class GenerationResult {
  final Gua gua;
  final GeneratorMethod method;

  const GenerationResult({required this.gua, required this.method});
}

/// Generates and retrieves Gua (hexagrams) for the I-Ching app.
///
/// Supports:
/// - Random Gua generation (with user consent)
/// - Explicit Gua detection from user input
/// - Multiple generator methods with different interpretation prompts
/// - Gua association with conversations
class GuaGenerator {
  final DatabaseService _db;
  final _random = Random();
  List<Gua>? _allGua;

  GuaGenerator(this._db); // cached after first load

  Future<List<Gua>> get _guaList async {
    _allGua ??= await _db.getAllGua();
    return _allGua!;
  }

  // ---------------------------------------------------------------------------
  // Generation
  // ---------------------------------------------------------------------------

  /// Pick a random hexagram from the 64.
  Future<GenerationResult> generateRandom() async {
    final list = await _guaList;
    return GenerationResult(
      gua: list[_random.nextInt(list.length)],
      method: GeneratorMethod.randomCast,
    );
  }

  /// Try to find a Gua mentioned in [text]. Returns `null` if none found.
  ///
  /// Matches:
  /// - Chinese names: 乾, 坤, 屯, 蒙, etc.
  /// - Pinyin: qian, kun, zhun, etc.
  /// - Numbers: "gua 1", "hexagram 23", "gua 64"
  Future<GenerationResult?> findInText(String text) async {
    final list = await _guaList;
    final lower = text.toLowerCase();

    // 1. Try matching a Gua number
    final numberMatch = RegExp(r'(?:gua|hexagram|卦)\s*[:：#]?\s*(\d{1,2})')
        .firstMatch(lower);
    if (numberMatch != null) {
      final num = int.tryParse(numberMatch.group(1)!);
      if (num != null && num >= 1 && num <= 64) {
        return GenerationResult(
          gua: list.firstWhere(
            (g) => g.guaCode == num,
            orElse: () => list[_random.nextInt(list.length)],
          ),
          method: GeneratorMethod.userRequested,
        );
      }
    }

    // 2. Try matching Chinese name
    for (final gua in list) {
      final chineseName = gua.guaName.split(' ').first;
      if (lower.contains(chineseName)) {
        return GenerationResult(
          gua: gua,
          method: GeneratorMethod.userRequested,
        );
      }
    }

    // 3. Try matching pinyin (accents stripped)
    for (final gua in list) {
      final pinyinMatch = RegExp(r'\(([^)]+)\)').firstMatch(gua.guaName);
      if (pinyinMatch != null) {
        final pinyin = pinyinMatch.group(1)!.toLowerCase();
        final stripped = _stripAccents(pinyin);
        if (stripped.isNotEmpty &&
            RegExp('\\b$stripped\\b', caseSensitive: false)
                .hasMatch(lower)) {
          return GenerationResult(
            gua: gua,
            method: GeneratorMethod.userRequested,
          );
        }
      }
    }

    return null;
  }

  /// Strip common diacritics from pinyin so "qián" matches "qian".
  static String _stripAccents(String s) {
    return s
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c');
  }

  // ---------------------------------------------------------------------------
  // Context prompt for LLM
  // ---------------------------------------------------------------------------

  /// Format a [GenerationResult] as a context string for the LLM.
  ///
  /// Each [GeneratorMethod] produces a different framing so the LLM
  /// interprets the hexagram differently.
  String formatContext(GenerationResult result) {
    final gua = result.gua;
    final header = _methodHeader(result.method);
    return '$header\n'
        'Hexagram: ${gua.guaName} (gua code ${gua.guaCode})\n'
        '${gua.guaContent}\n'
        '${gua.guaSummary}\n'
        'Source: ${gua.source}';
  }

  /// The opening line that frames how this hexagram came about.
  String _methodHeader(GeneratorMethod method) {
    switch (method) {
      case GeneratorMethod.userRequested:
        return 'The user has specifically asked about this hexagram. '
            'Share its wisdom as it relates to their situation.';
      case GeneratorMethod.randomCast:
        return 'A hexagram has been cast at the user\'s request. '
            'The I-Ching offers this reflection for their contemplation.';
      case GeneratorMethod.automatic:
        return 'A hexagram has been drawn to offer perspective. '
            'Present its meaning gently as an invitation for reflection.';
    }
  }

  // ---------------------------------------------------------------------------
  // Conversation association
  // ---------------------------------------------------------------------------

  /// Associate a Gua with a conversation by updating [lastGuaId].
  Future<void> associateWithConversation(int conversationId, Gua gua) async {
    final conv = await _db.getConversation(conversationId);
    if (conv != null) {
      await _db.updateConversation(
        conv.copyWith(
          lastGuaId: gua.id,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
