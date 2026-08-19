/// Maps a (lower trigram, upper trigram) pair to its resulting hexagram.
///
/// Trigram codes follow the binary line pattern (bottom line = LSB), offset
/// to 1-based:
/// 天=乾=8(111), 澤=兌=7(110), 火=離=6(101), 雷=震=5(100),
/// 風=巽=4(011), 水=坎=3(010), 山=艮=2(001), 地=坤=1(000).
///
/// The [resultCode] is the binary hexagram code, shifted to 1-based:
/// `(lowCode - 1) * 8 + highCode`, giving a range of 1–64.
class TrigramHexagram {
  /// Lower (bottom) trigram code, 1–8.
  final int lowCode;

  /// Lower trigram name (e.g. "天").
  final String lowDesc;

  /// Upper (top) trigram code, 1–8.
  final int highCode;

  /// Upper trigram name (e.g. "天").
  final String highName;

  /// Resulting hexagram binary code, 1–64.
  final int resultCode;

  /// Resulting hexagram name (e.g. "乾為天").
  final String resultName;

  const TrigramHexagram({
    required this.lowCode,
    required this.lowDesc,
    required this.highCode,
    required this.highName,
    required this.resultCode,
    required this.resultName,
  });

  Map<String, dynamic> toMap() {
    return {
      'low_code': lowCode,
      'low_desc': lowDesc,
      'high_code': highCode,
      'high_name': highName,
      'result_code': resultCode,
      'result_name': resultName,
    };
  }

  factory TrigramHexagram.fromMap(Map<String, dynamic> map) {
    return TrigramHexagram(
      lowCode: map['low_code'] as int,
      lowDesc: map['low_desc'] as String,
      highCode: map['high_code'] as int,
      highName: map['high_name'] as String,
      resultCode: map['result_code'] as int,
      resultName: map['result_name'] as String,
    );
  }

  @override
  String toString() =>
      'TrigramHexagram(low: $lowCode$lowDesc, high: $highCode$highName, '
      'result: $resultCode $resultName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrigramHexagram &&
          runtimeType == other.runtimeType &&
          lowCode == other.lowCode &&
          lowDesc == other.lowDesc &&
          highCode == other.highCode &&
          highName == other.highName &&
          resultCode == other.resultCode &&
          resultName == other.resultName;

  @override
  int get hashCode => Object.hash(
      lowCode, lowDesc, highCode, highName, resultCode, resultName);
}
