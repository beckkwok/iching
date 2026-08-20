import 'dart:math';
import '../data/trigram_hexagram_data.dart';
import '../models/gua.dart';
import '../models/yao_line_type.dart';
import 'database_service.dart';

/// How a hexagram was generated. Each method implies a different framing
/// for the LLM interpretation prompt.
enum GeneratorMethod {
  /// User explicitly named a hexagram (by name, number, or pinyin).
  manual,

  /// System randomly generated a hexagram with user consent.
  systemGenerated,
}

/// Result of a Gua generation or lookup.
class GenerationResult {
  final Gua gua;
  final GeneratorMethod method;

  /// The six cast yao lines, bottom (index 0) to top (index 5).
  ///
  /// `true` = yang (solid), `false` = yin (broken). Empty for [GeneratorMethod.manual].
  final List<bool> lines;

  /// The six cast line types (老陰/少陽/少陰/老陽), bottom → top.
  ///
  /// Empty for [GeneratorMethod.manual] or when only boolean lines are known.
  final List<YaoLineType> lineTypes;

  const GenerationResult({
    required this.gua,
    required this.method,
    this.lines = const [],
    this.lineTypes = const [],
  });

  /// True if [lines] holds the six cast lines (system-generated casts).
  bool get hasCast => lines.length == 6;

  /// Convenience: the 老陰/少陽/少陰/老陽 labels, bottom → top.
  List<String> get lineTypeLabels =>
      lineTypes.map((t) => t.label).toList();
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

  /// Cast six yao lines (bottom → top) using the traditional three-coin
  /// method and resolve the resulting hexagram from [TrigramHexagramData].
  ///
  /// Each line is cast by summing three coins (2 = yin, 3 = yang), yielding
  /// 6/7/8/9 → 老陰/少陽/少陰/老陽. The lower trigram is lines 1–3 (indices
  /// 0–2); the upper trigram is lines 4–6 (indices 3–5). Both the boolean
  /// [lines] and the full [YaoLineType] list are stored on the result.
  Future<GenerationResult> generateRandom() async {
    final lineTypes = List.generate(6, (_) => _castLine());
    final lines = lineTypes.map((t) => t.isYang).toList();
    return resolveCast(lines, lineTypes: lineTypes);
  }

  /// Cast a single yao line with three coins. Each coin is 2 (yin) or 3
  /// (yang); the sum determines the type:
  /// 6=老陰, 7=少陽, 8=少陰, 9=老陽.
  YaoLineType _castLine() {
    var sum = 0;
    for (var i = 0; i < 3; i++) {
      sum += _random.nextBool() ? 3 : 2;
    }
    return YaoLineType.fromValue(sum);
  }

  /// Resolve a fixed 6-line [lines] cast (bottom → top) into a hexagram,
  /// using [TrigramHexagramData] and the seeded gua table.
  ///
  /// Optionally pass [lineTypes] (the 老陰/少陽/少陰/老陽 per line) to keep
  /// on the result. Throws [ArgumentError] if [lines] is not exactly 6.
  Future<GenerationResult> resolveCast(
    List<bool> lines, {
    List<YaoLineType> lineTypes = const [],
  }) async {
    if (lines.length != 6) {
      throw ArgumentError.value(
          lines, 'lines', 'A cast must contain exactly 6 lines');
    }
    final list = await _guaList;
    return GenerationResult(
      gua: _resolveGua(list, lines),
      method: GeneratorMethod.systemGenerated,
      lines: lines,
      lineTypes: lineTypes,
    );
  }

  /// Find the hexagram in [list] that matches a 6-line cast [lines].
  Gua _resolveGua(List<Gua> list, List<bool> lines) {
    if (lines.length == 6) {
      final lowerCode =
          TrigramHexagramData.linesToCode(lines[0], lines[1], lines[2]);
      final upperCode =
          TrigramHexagramData.linesToCode(lines[3], lines[4], lines[5]);
      final entry = TrigramHexagramData.byCodes(lowerCode, upperCode);
      if (entry != null) {
        // Prefer an exact name match (卦名 == resultName, e.g. "地風升").
        for (final gua in list) {
          final name = gua.content?.guaName ?? gua.guaName;
          if (name == entry.resultName) return gua;
        }
        // Fall back to matching the 6-line pattern from each gua's 卦象.
        for (final gua in list) {
          if (_listsEqual(
              TrigramHexagramData.linesFromSymbol(gua.content?.guaSymbol ?? ''),
              lines)) {
            return gua;
          }
        }
      }
    }
    // Unknown cast — fall back to a random hexagram.
    return list[_random.nextInt(list.length)];
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
          method: GeneratorMethod.manual,
        );
      }
    }

    // 2. Try matching Chinese name
    for (final gua in list) {
      final chineseName = gua.guaName.split(' ').first;
      if (lower.contains(chineseName)) {
        return GenerationResult(
          gua: gua,
          method: GeneratorMethod.manual,
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
            method: GeneratorMethod.manual,
          );
        }
      }
    }

    return null;
  }

  /// Element-wise equality for two [List]s (Dart `==` on lists is identity).
  static bool _listsEqual(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    final content = gua.content;
    final buffer = StringBuffer('$header\n');
    buffer.writeln('Hexagram: ${gua.guaName} (gua code ${gua.guaCode})');
    if (result.hasCast) {
      buffer.writeln('Cast lines (bottom to top): '
          '${result.lines.map((l) => l ? 'yang' : 'yin').join(', ')}');
      if (result.lineTypes.length == 6) {
        buffer.writeln('Line types (bottom to top): '
            '${result.lineTypeLabels.join(', ')}');
      }
    }
    if (content != null) {
      if (content.guaCi.isNotEmpty) {
        buffer.writeln('卦辭: ${content.guaCi}');
      }
      if (content.tuanZhuan.isNotEmpty) {
        buffer.writeln('彖傳: ${content.tuanZhuan}');
      }
      if (content.daXiangZhuan.isNotEmpty) {
        buffer.writeln('大象傳: ${content.daXiangZhuan}');
      }
      if (content.symbolicMeaning.summary.isNotEmpty) {
        buffer.writeln('象徵總結: ${content.symbolicMeaning.summary}');
      }
    } else {
      buffer.writeln(gua.guaContent);
    }
    return buffer.toString();
  }

  /// The opening line that frames how this hexagram came about.
  String _methodHeader(GeneratorMethod method) {
    switch (method) {
      case GeneratorMethod.manual:
        return 'The user has specifically asked about this hexagram. '
            'Share its wisdom as it relates to their situation.';
      case GeneratorMethod.systemGenerated:
        return 'A hexagram has been cast at the user\'s request. '
            'The I-Ching offers this reflection for their contemplation.';
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
