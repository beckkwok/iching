import '../models/trigram_hexagram.dart';

/// Constant mapping of (lower trigram, upper trigram) → hexagram.
///
/// Derived verbatim from the 64-row CSV, with codes shifted to 1-based:
/// trigrams are 1–8 (地=1 … 天=8) and `resultCode` = `(lowCode - 1) * 8 +
/// highCode`, spanning 1–64. `resultName` is the classical name
/// (e.g. "乾為天").
class TrigramHexagramData {
  TrigramHexagramData._();

  static const List<TrigramHexagram> all = [
    // low=8 (天/乾)
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 8, highName: '天', resultCode: 64, resultName: '乾為天'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 7, highName: '澤', resultCode: 63, resultName: '澤天夬'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 6, highName: '火', resultCode: 62, resultName: '火天大有'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 5, highName: '雷', resultCode: 61, resultName: '雷天大壯'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 4, highName: '風', resultCode: 60, resultName: '風天小畜'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 3, highName: '水', resultCode: 59, resultName: '水天需'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 2, highName: '山', resultCode: 58, resultName: '山天大畜'),
    TrigramHexagram(lowCode: 8, lowDesc: '天', highCode: 1, highName: '地', resultCode: 57, resultName: '地天泰'),
    // low=7 (澤/兌)
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 8, highName: '天', resultCode: 56, resultName: '天澤履'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 7, highName: '澤', resultCode: 55, resultName: '兌為澤'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 6, highName: '火', resultCode: 54, resultName: '火澤睽'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 5, highName: '雷', resultCode: 53, resultName: '雷澤歸妹'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 4, highName: '風', resultCode: 52, resultName: '風澤中孚'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 3, highName: '水', resultCode: 51, resultName: '水澤節'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 2, highName: '山', resultCode: 50, resultName: '山澤損'),
    TrigramHexagram(lowCode: 7, lowDesc: '澤', highCode: 1, highName: '地', resultCode: 49, resultName: '地澤臨'),
    // low=6 (火/離)
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 8, highName: '天', resultCode: 48, resultName: '天火同人'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 7, highName: '澤', resultCode: 47, resultName: '澤火革'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 6, highName: '火', resultCode: 46, resultName: '離為火'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 5, highName: '雷', resultCode: 45, resultName: '雷火豐'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 4, highName: '風', resultCode: 44, resultName: '風火家人'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 3, highName: '水', resultCode: 43, resultName: '水火既濟'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 2, highName: '山', resultCode: 42, resultName: '山火賁'),
    TrigramHexagram(lowCode: 6, lowDesc: '火', highCode: 1, highName: '地', resultCode: 41, resultName: '地火明夷'),
    // low=5 (雷/震)
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 8, highName: '天', resultCode: 40, resultName: '天雷無妄'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 7, highName: '澤', resultCode: 39, resultName: '澤雷隨'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 6, highName: '火', resultCode: 38, resultName: '火雷噬嗑'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 5, highName: '雷', resultCode: 37, resultName: '震為雷'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 4, highName: '風', resultCode: 36, resultName: '風雷益'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 3, highName: '水', resultCode: 35, resultName: '水雷屯'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 2, highName: '山', resultCode: 34, resultName: '山雷頤'),
    TrigramHexagram(lowCode: 5, lowDesc: '雷', highCode: 1, highName: '地', resultCode: 33, resultName: '地雷復'),
    // low=4 (風/巽)
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 8, highName: '天', resultCode: 32, resultName: '天風姤'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 7, highName: '澤', resultCode: 31, resultName: '澤風大過'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 6, highName: '火', resultCode: 30, resultName: '火風鼎'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 5, highName: '雷', resultCode: 29, resultName: '雷風恆'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 4, highName: '風', resultCode: 28, resultName: '巽為風'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 3, highName: '水', resultCode: 27, resultName: '水風井'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 2, highName: '山', resultCode: 26, resultName: '山風蠱'),
    TrigramHexagram(lowCode: 4, lowDesc: '風', highCode: 1, highName: '地', resultCode: 25, resultName: '地風升'),
    // low=3 (水/坎)
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 8, highName: '天', resultCode: 24, resultName: '天水訟'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 7, highName: '澤', resultCode: 23, resultName: '澤水困'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 6, highName: '火', resultCode: 22, resultName: '火水未濟'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 5, highName: '雷', resultCode: 21, resultName: '雷水解'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 4, highName: '風', resultCode: 20, resultName: '風水渙'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 3, highName: '水', resultCode: 19, resultName: '坎為水'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 2, highName: '山', resultCode: 18, resultName: '山水蒙'),
    TrigramHexagram(lowCode: 3, lowDesc: '水', highCode: 1, highName: '地', resultCode: 17, resultName: '水地師'),
    // low=2 (山/艮)
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 8, highName: '天', resultCode: 16, resultName: '天山遯'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 7, highName: '澤', resultCode: 15, resultName: '澤山咸'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 6, highName: '火', resultCode: 14, resultName: '火山旅'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 5, highName: '雷', resultCode: 13, resultName: '雷山小過'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 4, highName: '風', resultCode: 12, resultName: '風山漸'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 3, highName: '水', resultCode: 11, resultName: '水山蹇'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 2, highName: '山', resultCode: 10, resultName: '艮為山'),
    TrigramHexagram(lowCode: 2, lowDesc: '山', highCode: 1, highName: '地', resultCode: 9, resultName: '地山謙'),
    // low=1 (地/坤)
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 8, highName: '天', resultCode: 8, resultName: '天地否'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 7, highName: '澤', resultCode: 7, resultName: '澤地萃'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 6, highName: '火', resultCode: 6, resultName: '火地晉'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 5, highName: '雷', resultCode: 5, resultName: '雷地豫'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 4, highName: '風', resultCode: 4, resultName: '風地觀'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 3, highName: '水', resultCode: 3, resultName: '水地比'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 2, highName: '山', resultCode: 2, resultName: '山地剝'),
    TrigramHexagram(lowCode: 1, lowDesc: '地', highCode: 1, highName: '地', resultCode: 1, resultName: '坤為地'),
  ];

  /// Convert three trigram lines (bottom → top) into the 1-based trigram code.
  ///
  /// Each boolean is a yao line: `true` = yang (solid, 1), `false` = yin
  /// (broken, 0). The lines are treated as binary bits with the bottom line as
  /// the most significant, then offset to 1-based.
  ///
  /// Examples:
  /// - `linesToCode(true, true, true)` → 8 (天/乾)
  /// - `linesToCode(false, false, false)` → 1 (地/坤)
  /// - `linesToCode(true, true, false)` → 7 (澤/兌)
  ///
  /// Parameters are ordered from bottom to top (line 1 → line 3).
  static int linesToCode(bool bottom, bool middle, bool top) {
    final value = (bottom ? 4 : 0) + (middle ? 2 : 0) + (top ? 1 : 0);
    return value + 1;
  }

  /// Trigram-name → line pattern (bottom → top), used to parse 卦象 strings.
  static const Map<String, List<bool>> trigramLinePatterns = {
    '乾': [true, true, true], // ☰ Qián
    '兑': [true, true, false], // ☱ Duì (simplified)
    '兌': [true, true, false], // ☱ Duì (traditional)
    '离': [true, false, true], // ☲ Lí (simplified)
    '離': [true, false, true], // ☲ Lí (traditional)
    '震': [true, false, false], // ☳ Zhèn (yang at bottom)
    '巽': [false, true, true], // ☴ Xùn (yin at bottom)
    '坎': [false, true, false], // ☵ Kǎn
    '艮': [false, false, true], // ☶ Gèn (yang on top)
    '坤': [false, false, false], // ☷ Kūn
  };

  /// Parse a 卦象 string (e.g. "䷭（下巽上坤）") into a 6-line pattern,
  /// bottom (index 0) to top (index 5). Each element is `true` for a solid
  /// (yang) line or `false` for a broken (yin) line.
  static List<bool> linesFromSymbol(String symbol) {
    final match = RegExp(r'下([乾兑兌离離震巽坎艮坤])上([乾兑兌离離震巽坎艮坤])')
        .firstMatch(symbol);
    if (match == null) {
      return [false, false, false, false, false, false];
    }
    final lower =
        trigramLinePatterns[match.group(1)!] ?? [false, false, false];
    final upper =
        trigramLinePatterns[match.group(2)!] ?? [false, false, false];
    return [...lower, ...upper];
  }

  /// Look up a hexagram by [lowCode] and [highCode] (both 1–8).
  static TrigramHexagram? byCodes(int lowCode, int highCode) {
    for (final entry in all) {
      if (entry.lowCode == lowCode && entry.highCode == highCode) {
        return entry;
      }
    }
    return null;
  }

  /// Look up a hexagram by its binary [resultCode] (1–64).
  static TrigramHexagram? byResultCode(int resultCode) {
    for (final entry in all) {
      if (entry.resultCode == resultCode) {
        return entry;
      }
    }
    return null;
  }
}
