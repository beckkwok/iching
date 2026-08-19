import 'dart:convert';

/// Parsed representation of a hexagram's `gua_content` JSON blob.
///
/// The JSON schema (Chinese keys) is defined by the individual
/// `assets/hexagrams/gua_<n>.json` files. This model maps those keys to typed
/// Dart fields so the app can read hexagram details without string parsing.
class HexagramContent {
  /// 卦名 — hexagram name (e.g. "地風升").
  final String guaName;

  /// 卦序 — sequence number (1–64).
  final int guaSequence;

  /// 卦象 — hexagram symbol (e.g. "䷭（下巽上坤）").
  final String guaSymbol;

  /// 卦辭 — hexagram judgment statement.
  final String guaCi;

  /// 彖傳 — Tuan commentary.
  final String tuanZhuan;

  /// 大象傳 — Great Image commentary.
  final String daXiangZhuan;

  /// 爻辭 — the six lines, bottom (初六) to top (上六).
  final List<HexagramLine> lines;

  /// 象徵意義 — symbolic meaning breakdown.
  final SymbolicMeaning symbolicMeaning;

  /// 不同人解讀 — interpretations from various commentators.
  final List<Interpretation> interpretations;

  /// 備註 — remarks / source notes.
  final String remarks;

  const HexagramContent({
    required this.guaName,
    required this.guaSequence,
    required this.guaSymbol,
    required this.guaCi,
    required this.tuanZhuan,
    required this.daXiangZhuan,
    required this.lines,
    required this.symbolicMeaning,
    required this.interpretations,
    required this.remarks,
  });

  /// Parse a `gua_content` JSON string into a [HexagramContent].
  factory HexagramContent.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return HexagramContent.fromMap(map);
  }

  factory HexagramContent.fromMap(Map<String, dynamic> map) {
    return HexagramContent(
      guaName: _str(map['卦名']),
      guaSequence: _int(map['卦序']),
      guaSymbol: _str(map['卦象']),
      guaCi: _str(map['卦辭']),
      tuanZhuan: _str(map['彖傳']),
      daXiangZhuan: _str(map['大象傳']),
      lines: _list<HexagramLine>(
        map['爻辭'],
        (e) => HexagramLine.fromMap(e as Map<String, dynamic>),
      ),
      symbolicMeaning: SymbolicMeaning.fromMap(
        (map['象徵意義'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      interpretations: _list<Interpretation>(
        map['不同人解讀'],
        (e) => Interpretation.fromMap(e as Map<String, dynamic>),
      ),
      remarks: _str(map['備註']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '卦名': guaName,
      '卦序': guaSequence,
      '卦象': guaSymbol,
      '卦辭': guaCi,
      '彖傳': tuanZhuan,
      '大象傳': daXiangZhuan,
      '爻辭': lines.map((l) => l.toMap()).toList(),
      '象徵意義': symbolicMeaning.toMap(),
      '不同人解讀': interpretations.map((i) => i.toMap()).toList(),
      '備註': remarks,
    };
  }

  String toJson() => jsonEncode(toMap());

  HexagramContent copyWith({
    String? guaName,
    int? guaSequence,
    String? guaSymbol,
    String? guaCi,
    String? tuanZhuan,
    String? daXiangZhuan,
    List<HexagramLine>? lines,
    SymbolicMeaning? symbolicMeaning,
    List<Interpretation>? interpretations,
    String? remarks,
  }) {
    return HexagramContent(
      guaName: guaName ?? this.guaName,
      guaSequence: guaSequence ?? this.guaSequence,
      guaSymbol: guaSymbol ?? this.guaSymbol,
      guaCi: guaCi ?? this.guaCi,
      tuanZhuan: tuanZhuan ?? this.tuanZhuan,
      daXiangZhuan: daXiangZhuan ?? this.daXiangZhuan,
      lines: lines ?? this.lines,
      symbolicMeaning: symbolicMeaning ?? this.symbolicMeaning,
      interpretations: interpretations ?? this.interpretations,
      remarks: remarks ?? this.remarks,
    );
  }

  @override
  String toString() =>
      'HexagramContent(guaName: $guaName, guaSequence: $guaSequence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HexagramContent &&
          runtimeType == other.runtimeType &&
          guaName == other.guaName &&
          guaSequence == other.guaSequence &&
          guaSymbol == other.guaSymbol &&
          guaCi == other.guaCi &&
          tuanZhuan == other.tuanZhuan &&
          daXiangZhuan == other.daXiangZhuan &&
          lines == other.lines &&
          symbolicMeaning == other.symbolicMeaning &&
          interpretations == other.interpretations &&
          remarks == other.remarks;

  @override
  int get hashCode => Object.hash(guaName, guaSequence, guaSymbol, guaCi,
      tuanZhuan, daXiangZhuan, lines, symbolicMeaning, interpretations, remarks);

  static String _str(dynamic v) => v is String ? v : '';
  static int _int(dynamic v) => v is num ? v.toInt() : 0;

  static List<T> _list<T>(dynamic v, T Function(dynamic) item) {
    if (v is! List) return const [];
    return v.map(item).toList();
  }
}

/// A single line (爻) of a hexagram.
class HexagramLine {
  /// 爻位 — line position (e.g. "初六", "九二", "上六").
  final String position;

  /// 爻辭 — line text.
  final String text;

  /// 小象傳 — Small Image commentary for this line.
  final String xiaoXiangZhuan;

  const HexagramLine({
    required this.position,
    required this.text,
    required this.xiaoXiangZhuan,
  });

  factory HexagramLine.fromMap(Map<String, dynamic> map) {
    return HexagramLine(
      position: map['爻位'] as String? ?? '',
      text: map['爻辭'] as String? ?? '',
      xiaoXiangZhuan: map['小象傳'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        '爻位': position,
        '爻辭': text,
        '小象傳': xiaoXiangZhuan,
      };

  HexagramLine copyWith({
    String? position,
    String? text,
    String? xiaoXiangZhuan,
  }) {
    return HexagramLine(
      position: position ?? this.position,
      text: text ?? this.text,
      xiaoXiangZhuan: xiaoXiangZhuan ?? this.xiaoXiangZhuan,
    );
  }

  @override
  String toString() => 'HexagramLine(position: $position, text: "$text")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HexagramLine &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          text == other.text &&
          xiaoXiangZhuan == other.xiaoXiangZhuan;

  @override
  int get hashCode => Object.hash(position, text, xiaoXiangZhuan);
}

/// 象徵意義 — symbolic meaning section.
class SymbolicMeaning {
  /// 基本卦象 — basic trigram composition.
  final BasicSymbol basicSymbol;

  /// 主要象徵 — main symbolic themes.
  final List<MainSymbol> mainSymbols;

  /// 生活與占事常見象徵 — life / divination applications.
  final Map<String, String> lifeSymbols;

  /// 總結 — overall summary.
  final String summary;

  const SymbolicMeaning({
    required this.basicSymbol,
    required this.mainSymbols,
    required this.lifeSymbols,
    required this.summary,
  });

  factory SymbolicMeaning.fromMap(Map<String, dynamic> map) {
    final lifeMap = (map['生活與占事常見象徵'] as Map?) ?? const {};
    return SymbolicMeaning(
      basicSymbol: BasicSymbol.fromMap(
        (map['基本卦象'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      mainSymbols: HexagramContent._list<MainSymbol>(
        map['主要象徵'],
        (e) => MainSymbol.fromMap(e as Map<String, dynamic>),
      ),
      lifeSymbols: lifeMap.map((k, v) => MapEntry(k.toString(), v.toString())),
      summary: map['總結'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        '基本卦象': basicSymbol.toMap(),
        '主要象徵': mainSymbols.map((s) => s.toMap()).toList(),
        '生活與占事常見象徵': lifeSymbols,
        '總結': summary,
      };

  SymbolicMeaning copyWith({
    BasicSymbol? basicSymbol,
    List<MainSymbol>? mainSymbols,
    Map<String, String>? lifeSymbols,
    String? summary,
  }) {
    return SymbolicMeaning(
      basicSymbol: basicSymbol ?? this.basicSymbol,
      mainSymbols: mainSymbols ?? this.mainSymbols,
      lifeSymbols: lifeSymbols ?? this.lifeSymbols,
      summary: summary ?? this.summary,
    );
  }

  @override
  String toString() => 'SymbolicMeaning(summary: "$summary")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymbolicMeaning &&
          runtimeType == other.runtimeType &&
          basicSymbol == other.basicSymbol &&
          mainSymbols == other.mainSymbols &&
          lifeSymbols == other.lifeSymbols &&
          summary == other.summary;

  @override
  int get hashCode =>
      Object.hash(basicSymbol, mainSymbols, lifeSymbols, summary);
}

/// 基本卦象 — basic trigram composition.
class BasicSymbol {
  /// 卦體 — trigram structure (e.g. "下巽上坤（䷭）").
  final String composition;

  /// 自然取象 — natural image (e.g. "地中生木").
  final String naturalImage;

  /// 說明 — explanation.
  final String explanation;

  const BasicSymbol({
    required this.composition,
    required this.naturalImage,
    required this.explanation,
  });

  factory BasicSymbol.fromMap(Map<String, dynamic> map) {
    return BasicSymbol(
      composition: map['卦體'] as String? ?? '',
      naturalImage: map['自然取象'] as String? ?? '',
      explanation: map['說明'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        '卦體': composition,
        '自然取象': naturalImage,
        '說明': explanation,
      };

  BasicSymbol copyWith({
    String? composition,
    String? naturalImage,
    String? explanation,
  }) {
    return BasicSymbol(
      composition: composition ?? this.composition,
      naturalImage: naturalImage ?? this.naturalImage,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  String toString() => 'BasicSymbol(composition: $composition)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BasicSymbol &&
          runtimeType == other.runtimeType &&
          composition == other.composition &&
          naturalImage == other.naturalImage &&
          explanation == other.explanation;

  @override
  int get hashCode => Object.hash(composition, naturalImage, explanation);
}

/// A single 主要象徵 item.
class MainSymbol {
  /// 標題 — theme title.
  final String title;

  /// 內容 — theme content.
  final String content;

  const MainSymbol({required this.title, required this.content});

  factory MainSymbol.fromMap(Map<String, dynamic> map) {
    return MainSymbol(
      title: map['標題'] as String? ?? '',
      content: map['內容'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'標題': title, '內容': content};

  MainSymbol copyWith({String? title, String? content}) {
    return MainSymbol(title: title ?? this.title, content: content ?? this.content);
  }

  @override
  String toString() => 'MainSymbol(title: "$title")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainSymbol &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          content == other.content;

  @override
  int get hashCode => Object.hash(title, content);
}

/// 不同人解讀 — a single commentator's interpretation.
class Interpretation {
  /// 解讀者 — commentator name.
  final String commentator;

  /// 卦辭解讀 — interpretation of the hexagram judgment.
  final String judgmentInterpretation;

  /// 爻辭解讀 — per-line interpretations, keyed by line position.
  final Map<String, String> lineInterpretations;

  const Interpretation({
    required this.commentator,
    required this.judgmentInterpretation,
    required this.lineInterpretations,
  });

  factory Interpretation.fromMap(Map<String, dynamic> map) {
    final lines = (map['爻辭解讀'] as Map?) ?? const {};
    return Interpretation(
      commentator: map['解讀者'] as String? ?? '',
      judgmentInterpretation: map['卦辭解讀'] as String? ?? '',
      lineInterpretations:
          lines.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  Map<String, dynamic> toMap() => {
        '解讀者': commentator,
        '卦辭解讀': judgmentInterpretation,
        '爻辭解讀': lineInterpretations,
      };

  Interpretation copyWith({
    String? commentator,
    String? judgmentInterpretation,
    Map<String, String>? lineInterpretations,
  }) {
    return Interpretation(
      commentator: commentator ?? this.commentator,
      judgmentInterpretation: judgmentInterpretation ?? this.judgmentInterpretation,
      lineInterpretations: lineInterpretations ?? this.lineInterpretations,
    );
  }

  @override
  String toString() => 'Interpretation(commentator: "$commentator")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interpretation &&
          runtimeType == other.runtimeType &&
          commentator == other.commentator &&
          judgmentInterpretation == other.judgmentInterpretation &&
          lineInterpretations == other.lineInterpretations;

  @override
  int get hashCode =>
      Object.hash(commentator, judgmentInterpretation, lineInterpretations);
}
