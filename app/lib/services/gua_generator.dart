import 'dart:math';
import '../data/trigram_hexagram_data.dart';
import '../models/gua.dart';
import '../models/hexagram_content.dart';
import '../models/yao_line_type.dart';
import 'hexagram_loader.dart';

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

  /// The six lines after flipping every changing line (老陰/老陽), bottom → top.
  ///
  /// Identical to [lines] when [lineTypes] has no changing lines (or is
  /// empty). This is the possible future state (issue #42).
  final List<bool> changedLines;

  /// The hexagram the [changedLines] resolve to, or `null` when no line is
  /// changing (issue #42).
  final Gua? changedGua;

  const GenerationResult({
    required this.gua,
    required this.method,
    this.lines = const [],
    this.lineTypes = const [],
    this.changedLines = const [],
    this.changedGua,
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
///
/// Hexagrams are loaded from [HexagramLoader] (JSON assets). Pass a loader
/// in tests to avoid depending on the bundled assets.
class GuaGenerator {
  final HexagramLoader _loader;
  final _random = Random();
  List<Gua>? _allGua;

  GuaGenerator([HexagramLoader? loader]) : _loader = loader ?? HexagramLoader();

  Future<List<Gua>> get _guaList async {
    _allGua ??= await _loader.loadAll();
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
  /// using [TrigramHexagramData] and the hexagrams loaded from JSON assets.
  ///
  /// Optionally pass [lineTypes] (the 老陰/少陽/少陰/老陽 per line) to keep
  /// on the result. Throws [ArgumentError] if [lines] is not exactly 6.
  Future<GenerationResult> resolveCast(
    List<bool> lines, {
    List<YaoLineType> lineTypes = const [],
    GeneratorMethod method = GeneratorMethod.systemGenerated,
  }) async {
    if (lines.length != 6) {
      throw ArgumentError.value(
          lines, 'lines', 'A cast must contain exactly 6 lines');
    }
    final list = await _guaList;
    // Flip every changing line (老陰/老陽) to get the changed hexagram
    // (issue #42); unchanged casts keep identical lines.
    final changedLines = List<bool>.generate(6, (i) {
      final typesChanging =
          lineTypes.length == 6 && lineTypes[i].isChanging;
      return typesChanging ? !lines[i] : lines[i];
    });
    final hasChanging = lineTypes.length == 6 &&
        lineTypes.any((t) => t.isChanging);
    return GenerationResult(
      gua: _resolveGua(list, lines),
      method: method,
      lines: lines,
      lineTypes: lineTypes,
      changedLines: changedLines,
      changedGua: hasChanging ? _resolveGua(list, changedLines) : null,
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

  /// Element-wise equality for two [List]s (Dart `==` on lists is identity).
  static bool _listsEqual(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
      _writeContent(buffer, content);
    } else {
      buffer.writeln(gua.guaContent);
    }
    return buffer.toString();
  }

  /// Format the changing lines (變爻) as context for a follow-up
  /// interpretation step (issue #5 / #79).
  ///
  /// Returns an empty string when [result] has no changing lines or no
  /// parseable content.
  String formatChangingLinesContext(GenerationResult result) {
    if (result.lineTypes.length != 6) return '';
    final content = result.gua.content;
    if (content == null) return '';

    final changing = <int>[
      for (var i = 0; i < 6; i++)
        if (result.lineTypes[i].isChanging) i,
    ];
    if (changing.isEmpty) return '';

    final buffer = StringBuffer(
      'Changing lines (變爻) in ${result.gua.guaName}, bottom to top:\n',
    );
    for (final i in changing) {
      final type = result.lineTypes[i];
      buffer.write('- Line ${i + 1} (${type.label})');
      if (i < content.lines.length) {
        final line = content.lines[i];
        if (line.position.isNotEmpty) buffer.write(' ${line.position}');
        if (line.text.isNotEmpty) buffer.write(': ${line.text}');
        if (line.xiaoXiangZhuan.isNotEmpty) {
          buffer.write('\n  小象傳: ${line.xiaoXiangZhuan}');
        }
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// Format the changed hexagram (變卦) as context for a follow-up
  /// interpretation step (issue #5 / #79).
  ///
  /// Returns an empty string when the cast has no changed hexagram.
  String formatChangedHexagramContext(GenerationResult result) {
    final changed = result.changedGua;
    if (changed == null) return '';

    final buffer = StringBuffer(
      'Changed hexagram (變卦): ${changed.guaName} '
      '(gua code ${changed.guaCode})\n',
    );
    if (result.changedLines.length == 6) {
      buffer.writeln('Changed lines (bottom to top): '
          '${result.changedLines.map((l) => l ? 'yang' : 'yin').join(', ')}');
    }
    final content = changed.content;
    if (content != null) {
      _writeContent(buffer, content);
    } else {
      buffer.writeln(changed.guaContent);
    }
    return buffer.toString().trim();
  }

  /// Conventional (朱熹) rule table for 0–6 changing lines (issue #90).
  ///
  /// Keep this table as the single source of truth when the reading rules
  /// change. [formatInterpretationContext] uses the same count to select text.
  static const Map<int, String> _interpretationRuleSummaries = {
    0: 'No changing lines: read the original judgment (本卦卦辭).',
    1: 'One changing line: read that line in the original hexagram '
        '(本卦變爻的爻辭).',
    2: 'Two changing lines: read both lines in the original hexagram; '
        'the upper changing line is primary (以上爻為主).',
    3: 'Three changing lines: read the original and changed judgments '
        '(本卦卦辭 + 變卦卦辭).',
    4: 'Four changing lines: read the two stable lines in the changed '
        'hexagram (變卦中兩個不變爻的爻辭).',
    5: 'Five changing lines: read the one stable line in the changed '
        'hexagram (變卦中唯一不變爻的爻辭).',
    6: 'Six changing lines: read the changed judgment (變卦卦辭); '
        'for 乾/坤 use 用九/用六.',
  };

  /// Format only the text(s) selected by the conventional changing-line rule
  /// (issue #90).
  ///
  /// Unlike [formatContext], this sends the text(s) the reader should consult
  /// rather than the whole hexagram. Labels make the 本卦 / 變卦 / 變爻
  /// relationship explicit. Reuses the line formatting added for #79.
  String formatInterpretationContext(GenerationResult result) {
    final changing = _changingLineIndices(result);
    final count = changing.length;
    final buffer = StringBuffer()
      ..writeln(_methodHeader(result.method))
      ..writeln('Changing lines (變爻): $count')
      ..writeln('Interpretation rule (變爻規則): '
          '${_interpretationRuleSummaries[count]}');

    if (count == 0) {
      _writeJudgment(buffer, 'Original', '本卦', result.gua);
    } else if (count == 1 || count == 2) {
      buffer.writeln('Original hexagram (本卦): ${result.gua.guaName} '
          '(gua code ${result.gua.guaCode})');
      for (var i = 0; i < changing.length; i++) {
        final role = count == 2
            ? (i == changing.length - 1
                ? 'primary — upper changing line'
                : 'secondary')
            : null;
        _writeLine(
          buffer,
          result.gua,
          changing[i],
          label: 'Changing line (變爻, 本卦第 ${changing[i] + 1} 爻',
          role: role,
        );
      }
    } else if (count == 3) {
      _writeJudgment(buffer, 'Original', '本卦', result.gua);
      final changed = result.changedGua;
      if (changed != null) {
        _writeJudgment(buffer, 'Changed', '變卦', changed);
      } else {
        buffer.writeln('Changed judgment (變卦卦辭): (not available)');
      }
    } else if (count == 4 || count == 5) {
      final changed = result.changedGua;
      if (changed == null) {
        buffer.writeln('Changed hexagram (變卦): (not available)');
      } else {
        buffer.writeln('Changed hexagram (變卦): ${changed.guaName} '
            '(gua code ${changed.guaCode})');
        for (final i in _stableLineIndices(result)) {
          _writeLine(
            buffer,
            changed,
            i,
            label: 'Stable line (不變爻, 變卦第 ${i + 1} 爻',
          );
        }
      }
    } else {
      final special = _specialLine(result.gua);
      if (special != null) {
        buffer.writeln('Original hexagram (本卦): ${result.gua.guaName} '
            '(gua code ${result.gua.guaCode})');
        buffer.writeln('Special line (${special.position}, 六爻皆變):');
        if (special.text.isNotEmpty) {
          buffer.writeln('  Line text (爻辭): ${special.text}');
        }
        if (special.xiaoXiangZhuan.isNotEmpty) {
          buffer.writeln('  Small Image (小象傳): ${special.xiaoXiangZhuan}');
        }
      } else {
        final changed = result.changedGua;
        if (changed != null) {
          _writeJudgment(buffer, 'Changed', '變卦', changed);
        } else {
          buffer.writeln('Changed judgment (變卦卦辭): (not available)');
        }
      }
    }
    return buffer.toString().trim();
  }

  /// Indices of the changing lines, bottom (0) to top (5).
  List<int> _changingLineIndices(GenerationResult result) {
    if (result.lineTypes.length != 6) return const [];
    return [
      for (var i = 0; i < 6; i++)
        if (result.lineTypes[i].isChanging) i,
    ];
  }

  /// Indices of the stable (non-changing) lines, bottom (0) to top (5).
  List<int> _stableLineIndices(GenerationResult result) {
    if (result.lineTypes.length != 6) return const [];
    return [
      for (var i = 0; i < 6; i++)
        if (!result.lineTypes[i].isChanging) i,
    ];
  }

  /// The 用九 / 用六 line, when present (only 乾/坤 carry these).
  HexagramLine? _specialLine(Gua gua) {
    final content = gua.content;
    if (content == null) return null;
    for (final line in content.lines) {
      if (line.position == '用九' || line.position == '用六') return line;
    }
    return null;
  }

  /// Write a hexagram name and its judgment (卦辭).
  void _writeJudgment(
    StringBuffer buffer,
    String english,
    String chinese,
    Gua gua,
  ) {
    buffer.writeln('$english hexagram ($chinese): ${gua.guaName} '
        '(gua code ${gua.guaCode})');
    final content = gua.content;
    if (content != null && content.guaCi.isNotEmpty) {
      buffer.writeln('$english judgment ($chinese卦辭): ${content.guaCi}');
    } else {
      buffer.writeln('$english judgment ($chinese卦辭): (not available)');
    }
  }

  /// Write one 爻辭 / 小象傳 from [gua] at [index], with [label] and [role].
  void _writeLine(
    StringBuffer buffer,
    Gua gua,
    int index, {
    required String label,
    String? role,
  }) {
    final content = gua.content;
    if (content == null || index >= content.lines.length) {
      buffer.writeln('$label): (text not available)');
      return;
    }
    final line = content.lines[index];
    final position = line.position.isEmpty ? '' : ' / ${line.position}';
    final suffix = role == null ? '' : ' [$role]';
    buffer.writeln('$label$position)$suffix:');
    if (line.text.isNotEmpty) {
      buffer.writeln('  Line text (爻辭): ${line.text}');
    }
    if (line.xiaoXiangZhuan.isNotEmpty) {
      buffer.writeln('  Small Image (小象傳): ${line.xiaoXiangZhuan}');
    }
  }

  /// Append the shared hexagram text sections (卦辭 / 彖傳 / 大象傳 /
  /// 象徵總結) to [buffer].
  void _writeContent(StringBuffer buffer, HexagramContent content) {
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
}
